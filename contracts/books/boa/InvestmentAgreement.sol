// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

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
        ShareTransferExt,
        ShareTransferInt,
        PreEmptive,
        FirstRefusal,
        TagAlong,
        DragAlong,
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
        uint16 class,
        uint16 seq,
        uint8 typeOfDeal,
        uint40 buyer,
        uint16 group,
        bytes32 shareNumber,
        uint16 preSeq
    ) internal pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0,class);
        _sn = _sn.sequenceToSN(2, seq);
        _sn[4] = bytes1(typeOfDeal);
        _sn = _sn.acctToSN(5, buyer);
        _sn = _sn.sequenceToSN(10, group);
        _sn = _sn.dateToSN(12, shareNumber.ssn());
        _sn = _sn.sequenceToSN(16, preSeq);

        return _sn.bytesToBytes32();
    }

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint16 class,
        uint40 buyer,
        uint16 group,
        uint16 preSeq
    ) public attorneyOrKeeper returns (bytes32) {
        require(buyer != 0, "buyer is ZERO address");
        require(group > 0, "ZERO group");

        if (shareNumber > bytes32(0)) {
            require(
                _bos.isShare(shareNumber.ssn()),
                "IA.createDeal: shareNumber not exist"
            );
            require(shareNumber.class() == class, "class NOT correct");

            if (_bos.isMember(buyer))
                require(
                    typeOfDeal == uint8(TypeOfDeal.ShareTransferInt) ||
                        typeOfDeal == uint8(TypeOfDeal.FirstRefusal) ||
                        typeOfDeal == uint8(TypeOfDeal.FreeGift),
                    "IA.createDeal: wrong typeOfDeal"
                );
            else
                require(
                    typeOfDeal == uint8(TypeOfDeal.ShareTransferExt) ||
                        typeOfDeal == uint8(TypeOfDeal.TagAlong) ||
                        typeOfDeal == uint8(TypeOfDeal.DragAlong),
                    "IA.createDeal: wrong typeOfDeal"
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

        emit CreateDeal(sn, shareNumber);

        return sn;
    }

    function updateDeal(
        uint16 seq,
        uint32 _unitPrice,
        uint64 paidPar,
        uint64 parValue,
        uint32 _closingDate
    ) public dealExist(seq) attorneyOrKeeper {
        require(parValue > 0, "parValue is ZERO");
        require(parValue >= paidPar, "paidPar overflow");
        require(_closingDate > block.number, "closingDate shall be future");

        Deal storage deal = _deals[seq];

        deal.unitPrice = _unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = _closingDate;

        emit UpdateDeal(deal.sn, _unitPrice, paidPar, parValue, _closingDate);
    }

    function delDeal(uint16 seq)
        external
        onlyPending
        dealExist(seq)
        onlyAttorney
    {
        Deal storage deal = _deals[seq];

        bytes32 sn = deal.sn;

        if (sn.ssnOfDeal() > 0) {
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
        uint32 _closingDate
    ) external onlyKeeper dealExist(seq) {
        Deal storage deal = _deals[seq];

        require(
            uint32(block.timestamp) < _closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            _closingDate <= closingDeadline(),
            "closingDate LATER than deadline"
        );

        require(
            deal.states.currentState == uint8(StateOfDeal.Locked),
            "Deal state wrong"
        );

        deal.states.pushToNextState();

        deal.hashLock = hashLock;

        if (_closingDate > 0) deal.closingDate = _closingDate;

        emit ClearDealCP(
            deal.sn,
            deal.states.currentState,
            hashLock,
            deal.closingDate
        );
    }

    function closeDeal(uint16 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyKeeper
    {
        Deal storage deal = _deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        require(block.timestamp + 15 minutes <= deal.closingDate, "MISSED closing date");

        deal.states.pushToNextState();

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(
        uint16 seq,
        // uint32 sigDate,
        string memory hashKey
    ) external onlyCleared(seq) onlyManager(1) {
        Deal storage deal = _deals[seq];

        require(
            deal.closingDate < block.timestamp - 15 minutes,
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
            uint64 paid,
            uint64 par,
            uint8 state, // 0-pending 1-locked 2-cleared 3-closed 4-terminated
            bytes32 hashLock
        )
    {
        Deal storage deal = _deals[seq];

        sn = deal.sn;
        paid = deal.paidPar;
        par = deal.parValue;
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

    function dealsList() external view returns (bytes32[] memory) {
        return _dealsList.values();
    }
}
