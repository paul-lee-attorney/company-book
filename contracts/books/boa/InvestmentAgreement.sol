/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, BOSSetting, SigPage {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.SeqList;
    using ObjsRepo for ObjsRepo.TimeLine;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        PreEmptive,
        ShareTransferExt,
        TagAlong,
        DragAlong,
        ShareTransferInt,
        FirstRefusal,
        FreeGift
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

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

    // seq => Deal
    mapping(uint16 => Deal) private _deals;

    ObjsRepo.SeqList private _dealsList;

    uint16 private _counterOfDeals;

    // ======== Parties ========

    // // party => seq
    // mapping(uint40 => EnumerableSet.UintSet) private _dealsConcerned;

    // // party => seq => buyer?
    // mapping(uint40 => mapping(uint16 => bool)) private _isBuyerOfDeal;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint16 seq) {
        require(
            _deals[seq].states.currentState == uint8(StateOfDeal.Cleared),
            "wrong stateOfDeal"
        );
        _;
    }

    modifier dealExist(uint16 seq) {
        require(_dealsList.contains(seq), "NOT a deal sn");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 class,
        uint16 seq,
        uint8 typeOfDeal,
        uint40 buyer,
        uint16 group,
        bytes32 shareNumber,
        uint16 preSeq
    ) internal pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn = _sn.sequenceToSN(1, seq);
        _sn[3] = bytes1(typeOfDeal);
        _sn = _sn.acctToSN(4, buyer);
        _sn = _sn.sequenceToSN(9, group);
        _sn = _sn.dateToSN(11, shareNumber.sequence());
        _sn = _sn.sequenceToSN(15, preSeq);

        return _sn.bytesToBytes32();
    }

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        uint40 buyer,
        uint16 group,
        uint16 preSeq
    ) public attorneyOrKeeper returns (bytes32) {
        require(buyer != 0, "buyer is ZERO address");
        require(group > 0, "ZERO group");

        if (shareNumber > bytes32(0)) {
            require(
                _bos.isShare(shareNumber.sequence()),
                "shareNumber not exist"
            );
            require(shareNumber.class() == class, "class NOT correct");

            if (_bos.isMember(buyer))
                require(
                    typeOfDeal == uint8(TypeOfDeal.ShareTransferInt) ||
                        typeOfDeal == uint8(TypeOfDeal.FirstRefusal) ||
                        typeOfDeal == uint8(TypeOfDeal.FreeGift),
                    "wrong typeOfDeal"
                );
            else
                require(
                    typeOfDeal == uint8(TypeOfDeal.ShareTransferExt) ||
                        typeOfDeal == uint8(TypeOfDeal.TagAlong) ||
                        typeOfDeal == uint8(TypeOfDeal.DragAlong),
                    "wrong typeOfDeal"
                );
        } else {
            require(class <= _bos.counterOfClasses(), "class overflow");
            require(
                typeOfDeal == uint8(TypeOfDeal.CapitalIncrease) ||
                    typeOfDeal == uint8(TypeOfDeal.PreEmptive),
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
            preSeq
        );

        Deal storage deal = _deals[_counterOfDeals];

        deal.sn = sn;
        deal.shareNumber = shareNumber;

        _dealsList.add(sn);

        if (_finalized) {
            if (
                shareNumber > bytes32(0) &&
                typeOfDeal != uint8(TypeOfDeal.DragAlong) &&
                typeOfDeal != uint8(TypeOfDeal.FreeGift)
            ) addBlank(shareNumber.shareholder(), _counterOfDeals);
            addBlank(buyer, _counterOfDeals);
        } else {
            if (shareNumber > bytes32(0))
                addBlank(shareNumber.shareholder(), 0);
            addBlank(buyer, 0);
        }

        // if (shareNumber > bytes32(0))
        //     _dealsConcerned[shareNumber.shareholder()].add(_counterOfDeals);

        // _dealsConcerned[buyer].add(_counterOfDeals);
        // _isBuyerOfDeal[buyer][_counterOfDeals] = true;

        emit CreateDeal(sn, shareNumber);

        return sn;
    }

    function updateDeal(
        uint16 seq,
        uint32 unitPrice,
        uint64 parValue,
        uint64 paidPar,
        uint32 closingDate
    ) public dealExist(seq) attorneyOrKeeper {
        require(parValue > 0, "parValue is ZERO");
        require(parValue >= paidPar, "paidPar overflow");
        require(closingDate > block.number, "closingDate shall be future");

        Deal storage deal = _deals[seq];

        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = closingDate;

        emit UpdateDeal(deal.sn, unitPrice, parValue, paidPar, closingDate);
    }

    function delDeal(uint16 seq)
        external
        onlyPending
        dealExist(seq)
        onlyAttorney
    {
        Deal storage deal = _deals[seq];

        bytes32 sn = deal.sn;

        if (sn.typeOfDeal() > uint8(TypeOfDeal.PreEmptive)) {
            removeBlank(deal.shareNumber.shareholder(), seq);
        }

        removeBlank(sn.buyerOfDeal(), seq);

        delete _deals[seq];
        _dealsList.remove(sn);

        emit DelDeal(sn);
    }

    function lockDealSubject(uint16 seq)
        public
        onlyKeeper
        dealExist(seq)
        returns (bool flag)
    {
        Deal storage deal = _deals[seq];
        if (deal.states.currentState == uint8(StateOfDeal.Drafting)) {
            deal.states.pushToNextState();
            flag = true;
            emit LockDealSubject(deal.sn);
        }
    }

    function releaseDealSubject(uint16 seq)
        external
        onlyKeeper
        dealExist(seq)
        returns (bool flag)
    {
        Deal storage deal = _deals[seq];
        if (deal.states.currentState >= uint8(StateOfDeal.Locked)) {
            deal.states.setState(uint8(StateOfDeal.Drafting));
            flag = true;
            emit ReleaseDealSubject(deal.sn);
        }
    }

    function clearDealCP(
        uint16 seq,
        bytes32 hashLock,
        uint32 closingDate
    ) external onlyKeeper dealExist(seq) {
        Deal storage deal = _deals[seq];

        require(
            uint32(block.timestamp) < closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            closingDate <= closingDeadline(),
            "closingDate LATER than deadline"
        );

        require(
            deal.states.currentState == uint8(StateOfDeal.Locked),
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

    function closeDeal(uint16 seq, string hashKey)
        external
        onlyCleared(seq)
        onlyKeeper
    {
        Deal storage deal = _deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        require(now + 15 minutes <= deal.closingDate, "MISSED closing date");

        deal.states.pushToNextState();

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(
        uint16 seq,
        // uint32 sigDate,
        string hashKey
    ) external onlyCleared(seq) onlyManager(1) {
        Deal storage deal = _deals[seq];

        require(
            deal.closingDate < now - 15 minutes,
            "NOT reached closing date"
        );

        require(
            deal.sn.typeOfDeal() != uint8(TypeOfDeal.FreeGift),
            "FreeGift deal cannot be revoked"
        );

        require(
            deal.states.currentState == uint8(StateOfDeal.Cleared),
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

    function takeGift(uint16 seq) external onlyKeeper {
        Deal storage deal = _deals[seq];

        require(
            deal.sn.typeOfDeal() == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            _deals[deal.sn.preSeqOfDeal()].states.currentState ==
                uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.unitPrice == 0, "unitPrice is not zero");

        require(
            deal.states.currentState == uint8(StateOfDeal.Locked),
            "wrong state"
        );

        deal.states.pushToNextState();
        deal.states.pushToNextState();

        emit CloseDeal(deal.sn, "0");
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function isDeal(uint16 seq) external view returns (bool) {
        return _dealsList.contains(seq);
    }

    function counterOfDeals() external view returns (uint16) {
        return _counterOfDeals;
    }

    function getDeal(uint16 seq)
        external
        view
        dealExist(seq)
        returns (
            bytes32 sn,
            uint64 parValue,
            uint64 paidPar,
            uint8 state, // 0-pending 1-locked 2-cleared 3-closed 4-terminated
            bytes32 hashLock
        )
    {
        Deal storage deal = _deals[seq];

        sn = deal.sn;
        parValue = deal.parValue;
        paidPar = deal.paidPar;
        state = deal.states.currentState;
        hashLock = deal.hashLock;
    }

    function unitPrice(uint16 seq)
        external
        view
        dealExist(seq)
        returns (uint32)
    {
        return _deals[seq].unitPrice;
    }

    function closingDate(uint16 seq)
        external
        view
        dealExist(seq)
        returns (uint32)
    {
        return _deals[seq].closingDate;
    }

    function shareNumberOfDeal(uint16 seq)
        external
        view
        dealExist(seq)
        returns (bytes32)
    {
        return _deals[seq].shareNumber;
    }

    function dealsList() external view returns (bytes32[]) {
        return _dealsList.values();
    }

    // function dealsConcerned(uint40 acct) external view returns (uint16[]) {
    //     require(isParty(acct), "not a party");
    //     return _dealsConcerned[acct].valuesToUint16();
    // }

    // function isBuyerOfDeal(uint40 acct, uint16 seq)
    //     external
    //     view
    //     returns (bool)
    // {
    //     require(isParty(acct), "not a party");
    //     return _isBuyerOfDeal[acct][seq];
    // }
}
