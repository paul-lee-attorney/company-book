/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, BOSSetting, SigPage {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.SeqList;
    using ObjsRepo for ObjsRepo.TimeLine;
    using ObjsRepo for ObjsRepo.FRDeals;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Deal {
        bytes32 sn;
        bytes32 shareNumber;
        uint32 unitPrice;
        uint64 parValue;
        uint64 paidPar;
        uint32 closingDate;
        ObjsRepo.TimeLine states;
        bytes32 hashLock;
    }

    // sequence => Deal
    mapping(uint16 => Deal) private _deals;

    ObjsRepo.SeqList private _dealsList;

    uint16 private _counterOfDeals;

    // ======== Parties ========

    // party => seq
    mapping(uint40 => EnumerableSet.UintSet) private _dealsConcerned;

    // party => seq => buyer?
    mapping(uint40 => mapping(uint16 => bool)) private _isBuyerOfDeal;

    // ==== FRDeals ====

    mapping(uint16 => ObjsRepo.FRDeals) private _frDeals;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint16 ssn) {
        require(
            _deals[ssn].states.currentState ==
                uint8(EnumsRepo.StateOfDeal.Cleared),
            "wrong stateOfDeal"
        );
        _;
    }

    modifier dealExist(uint16 ssn) {
        require(_dealsList.contains(ssn), "NOT a deal sn");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 class,
        uint16 sequence,
        uint8 typeOfDeal,
        uint40 buyer,
        uint16 group,
        bytes32 shareNumber,
        uint16 preSSN
    ) internal pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn[3] = bytes1(typeOfDeal);
        _sn = _sn.acctToSN(4, buyer);
        _sn = _sn.sequenceToSN(9, group);
        _sn = _sn.shortToSN(11, shareNumber.short());
        _sn = _sn.sequenceToSN(17, preSSN);

        return _sn.bytesToBytes32();
    }

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        uint40 buyer,
        uint16 group,
        uint16 preSSN
    ) public attorneyOrKeeper returns (bytes32) {
        require(buyer != 0, "buyer is ZERO address");
        require(group > 0, "ZERO group");

        if (shareNumber > bytes32(0)) {
            require(_bos.isShare(shareNumber.short()), "shareNumber not exist");
            require(shareNumber.class() == class, "class NOT correct");

            if (_bos.isMember(buyer))
                require(
                    typeOfDeal ==
                        uint8(EnumsRepo.TypeOfDeal.ShareTransferInt) ||
                        typeOfDeal ==
                        uint8(EnumsRepo.TypeOfDeal.FirstRefusal) ||
                        typeOfDeal == uint8(EnumsRepo.TypeOfDeal.FreeGift),
                    "wrong typeOfDeal"
                );
            else
                require(
                    typeOfDeal ==
                        uint8(EnumsRepo.TypeOfDeal.ShareTransferExt) ||
                        typeOfDeal == uint8(EnumsRepo.TypeOfDeal.TagAlong) ||
                        typeOfDeal == uint8(EnumsRepo.TypeOfDeal.DragAlong),
                    "wrong typeOfDeal"
                );
        } else {
            require(class <= _bos.counterOfClasses(), "class overflow");
            require(
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease) ||
                    typeOfDeal == uint8(EnumsRepo.TypeOfDeal.PreEmptive),
                "wrong typeOfDeal"
            );
        }

        _counterOfDeals++;

        bytes32 sn = _createSN(
            class,
            _counterOfDeals,
            typeOfDeal,
            buyer,
            group,
            shareNumber,
            preSSN
        );

        Deal storage deal = _deals[_counterOfDeals];

        deal.sn = sn;
        deal.shareNumber = shareNumber;

        _dealsList.add(sn);

        if (_finalized) {
            if (
                shareNumber > bytes32(0) &&
                typeOfDeal != uint8(EnumsRepo.TypeOfDeal.DragAlong) &&
                typeOfDeal != uint8(EnumsRepo.TypeOfDeal.FreeGift)
            ) addBlank(shareNumber.shareholder(), _counterOfDeals);
            addBlank(buyer, _counterOfDeals);
        } else {
            if (shareNumber > bytes32(0))
                addBlank(shareNumber.shareholder(), 0);
            addBlank(buyer, 0);
        }

        if (shareNumber > bytes32(0))
            _dealsConcerned[shareNumber.shareholder()].add(_counterOfDeals);

        _dealsConcerned[buyer].add(_counterOfDeals);
        _isBuyerOfDeal[buyer][_counterOfDeals] = true;

        emit CreateDeal(sn, shareNumber);

        return sn;
    }

    function updateDeal(
        uint16 ssn,
        uint32 unitPrice,
        uint64 parValue,
        uint64 paidPar,
        uint32 closingDate
    ) public dealExist(ssn) attorneyOrKeeper {
        require(parValue > 0, "parValue is ZERO");
        require(parValue >= paidPar, "paidPar overflow");
        require(closingDate > block.number, "closingDate shall be future");

        Deal storage deal = _deals[ssn];

        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = closingDate;

        emit UpdateDeal(deal.sn, unitPrice, parValue, paidPar, closingDate);
    }

    function delDeal(uint16 ssn)
        external
        onlyPending
        dealExist(ssn)
        onlyAttorney
    {
        Deal storage deal = _deals[ssn];

        bytes32 sn = deal.sn;

        if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive)) {
            removePartyFromDoc(deal.shareNumber.shareholder());
        }

        removePartyFromDoc(sn.buyerOfDeal());

        delete _deals[ssn];
        _dealsList.remove(sn);

        emit DelDeal(sn);
    }

    function lockDealSubject(uint16 ssn)
        public
        onlyKeeper
        dealExist(ssn)
        returns (bool flag)
    {
        Deal storage deal = _deals[ssn];
        if (deal.states.currentState == uint8(EnumsRepo.StateOfDeal.Drafting)) {
            deal.states.pushToNextState();
            flag = true;
            emit LockDealSubject(deal.sn);
        }
    }

    function releaseDealSubject(uint16 ssn)
        external
        onlyKeeper
        dealExist(ssn)
        returns (bool flag)
    {
        Deal storage deal = _deals[ssn];
        if (deal.states.currentState >= uint8(EnumsRepo.StateOfDeal.Locked)) {
            deal.states.setState(uint8(EnumsRepo.StateOfDeal.Drafting));
            flag = true;
            emit ReleaseDealSubject(deal.sn);
        }
    }

    function clearDealCP(
        uint16 ssn,
        bytes32 hashLock,
        uint32 closingDate
    ) external onlyKeeper dealExist(ssn) {
        Deal storage deal = _deals[ssn];

        require(
            uint32(block.timestamp) < closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            closingDate <= closingDeadline(),
            "closingDate LATER than deadline"
        );

        require(
            deal.states.currentState == uint8(EnumsRepo.StateOfDeal.Locked),
            "Deal state wrong"
        );

        deal.states.pushToNextState();

        deal.hashLock = hashLock;

        if (closingDate > 0) deal.closingDate = closingDate;

        emit ClearDealCP(
            deal.sn,
            deal.states.currentState,
            hashLock,
            deal.closingDate
        );
    }

    function closeDeal(uint16 ssn, string hashKey)
        external
        onlyCleared(ssn)
        onlyKeeper
    {
        Deal storage deal = _deals[ssn];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        require(now + 15 minutes <= deal.closingDate, "MISSED closing date");

        deal.states.pushToNextState();

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(
        uint16 ssn,
        // uint32 sigDate,
        string hashKey
    ) external onlyCleared(ssn) onlyManager(1) {
        Deal storage deal = _deals[ssn];

        require(
            deal.closingDate < now - 15 minutes,
            "NOT reached closing date"
        );

        require(
            deal.sn.typeOfDeal() != uint8(EnumsRepo.TypeOfDeal.FreeGift),
            "FreeGift deal cannot be revoked"
        );

        require(
            deal.states.currentState == uint8(EnumsRepo.StateOfDeal.Cleared),
            "wrong state of Deal"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.states.pushToNextState();
        deal.states.pushToNextState();

        emit RevokeDeal(deal.sn, hashKey);
    }

    function takeGift(uint16 ssn) external onlyKeeper {
        Deal storage deal = _deals[ssn];

        require(
            deal.sn.typeOfDeal() == uint8(EnumsRepo.TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            _deals[deal.sn.preSSNOfDeal()].states.currentState ==
                uint8(EnumsRepo.StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.unitPrice == 0, "unitPrice is not zero");

        require(
            deal.states.currentState == uint8(EnumsRepo.StateOfDeal.Locked),
            "wrong state"
        );

        deal.states.pushToNextState();
        deal.states.pushToNextState();

        emit CloseDeal(deal.sn, "0");
    }

    // ==== FRDeals ====

    function execFirstRefusalRight(
        uint16 ssn,
        uint40 acct,
        bytes32 sigHash
    ) external onlyKeeper dealExist(ssn) returns (bytes32) {
        Deal storage targetDeal = _deals[ssn];

        bytes32 snOfFR = createDeal(
            targetDeal.shareNumber == bytes32(0)
                ? uint8(EnumsRepo.TypeOfDeal.PreEmptive)
                : uint8(EnumsRepo.TypeOfDeal.FirstRefusal),
            targetDeal.shareNumber,
            targetDeal.sn.classOfDeal(),
            acct,
            _bos.groupNo(acct),
            targetDeal.sn.sequence()
        );

        uint64 weight = _bos.voteInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");

        if (_frDeals[ssn].execFirstRefusalRight(snOfFR.sequence(), weight) == 1)
            targetDeal.states.setState(uint8(EnumsRepo.StateOfDeal.Terminated));

        signDeal(ssn, acct, sigHash);

        return snOfFR;
    }

    function acceptFR(
        uint16 ssn,
        uint40 acct,
        bytes32 sigHash
    ) external onlyManager(1) dealExist(ssn) {
        Deal storage targetDeal = _deals[ssn];

        // uint16 len = _counterOfFR[ssn];
        uint16 len = _frDeals[ssn].counterOfFR;

        _frDeals[ssn].getRatioOfFRs();

        while (len > 0) {
            ObjsRepo.Record storage record = _frDeals[ssn].records[len];

            uint64 parValue = (targetDeal.parValue * record.ratio) / 10000;

            uint64 paidPar = (targetDeal.paidPar * record.ratio) / 10000;

            updateDeal(
                record.ssn,
                targetDeal.unitPrice,
                parValue,
                paidPar,
                targetDeal.closingDate
            );

            lockDealSubject(record.ssn);

            signDeal(record.ssn, acct, sigHash);

            len--;
        }

        emit AcceptFR(_deals[ssn].sn, acct);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function isDeal(uint16 ssn) external view returns (bool) {
        return _dealsList.contains(ssn);
    }

    function counterOfDeals() external view returns (uint16) {
        return _counterOfDeals;
    }

    function getDeal(uint16 ssn)
        external
        view
        dealExist(ssn)
        returns (
            bytes32 sn,
            uint64 parValue,
            uint64 paidPar,
            uint8 state, // 0-pending 1-locked 2-cleared 3-closed 4-terminated
            bytes32 hashLock
        )
    {
        Deal storage deal = _deals[ssn];

        sn = deal.sn;
        parValue = deal.parValue;
        paidPar = deal.paidPar;
        state = deal.states.currentState;
        hashLock = deal.hashLock;
    }

    function unitPrice(uint16 ssn)
        external
        view
        dealExist(ssn)
        returns (uint32)
    {
        return _deals[ssn].unitPrice;
    }

    function closingDate(uint16 ssn)
        external
        view
        dealExist(ssn)
        returns (uint32)
    {
        return _deals[ssn].closingDate;
    }

    function shareNumberOfDeal(uint16 ssn)
        external
        view
        dealExist(ssn)
        returns (bytes32)
    {
        return _deals[ssn].shareNumber;
    }

    function dealsList() external view returns (bytes32[]) {
        return _dealsList.values();
    }

    function dealsConcerned(uint40 acct) external view returns (uint16[]) {
        require(isParty(acct), "not a party");
        return _dealsConcerned[acct].valuesToUint16();
    }

    function isBuyerOfDeal(uint40 acct, uint16 seq)
        external
        view
        returns (bool)
    {
        require(isParty(acct), "not a party");
        return _isBuyerOfDeal[acct][seq];
    }

    // ==== FRDeals ====

    function counterOfFR(uint16 ssn) external view returns (uint16) {
        return _frDeals[ssn].counterOfFR;
    }

    function sumOfWeight(uint16 ssn) external view returns (uint64) {
        return _frDeals[ssn].sumOfWeight;
    }

    function isTargetDeal(uint16 ssn) external view returns (bool) {
        return _frDeals[ssn].counterOfFR > 0;
    }

    function frDeals(uint16 ssn) external view returns (uint16[]) {
        return _frDeals[ssn].getDeals();
    }
}
