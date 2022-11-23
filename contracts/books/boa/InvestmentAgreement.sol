// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is
    IInvestmentAgreement,
    BOSSetting,
    ROMSetting,
    SigPage
{
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText,
        PreEmptive,
        TagAlong,
        DragAlong,
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
        uint64 paid;
        uint64 par;
        uint32 unitPrice;
        uint32 closingDate;
        uint8 state;
        bytes32 hashLock;
    }

    // _deals[0] {
    //     unitPrice: counterOfDeal;
    //     state: typeOfIA;
    // }

    // seq => Deal
    mapping(uint256 => Deal) private _deals;

    EnumerableSet.Bytes32Set private _dealsList;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint16 seq) {
        require(
            _deals[seq].state == uint8(StateOfDeal.Cleared),
            "IA.onlyCleared: wrong stateOfDeal"
        );
        _;
    }

    modifier dealExist(uint16 seq) {
        require(
            _dealsList.contains(_deals[seq].sn),
            "IA.dealExist: deal not exist"
        );
        _;
    }

    //#################
    //##    写接口    ##
    //#################

    function createDeal(bytes32 sn, bytes32 shareNumber)
        external
        attorneyOrKeeper(uint8(TitleOfKeepers.SHAKeeper))
        returns (bytes32)
    {
        require(sn.buyerOfDeal() != 0, "IA.createDeal: ZERO buyer");
        require(sn.groupOfBuyer() != 0, "IA.createDeal: ZERO group");

        if (shareNumber != bytes32(0)) {
            require(
                _bos.isShare(shareNumber.ssn()),
                "IA.createDeal: shareNumber not exist"
            );
            require(
                shareNumber.class() == sn.class(),
                "IA.createDeal: class NOT correct"
            );

            if (_rom.isMember(sn.buyerOfDeal()))
                require(
                    sn.typeOfDeal() == uint8(TypeOfDeal.ShareTransferInt) ||
                        sn.typeOfDeal() == uint8(TypeOfDeal.FirstRefusal) ||
                        sn.typeOfDeal() == uint8(TypeOfDeal.FreeGift),
                    "IA.createDeal: wrong typeOfDeal"
                );
            else
                require(
                    sn.typeOfDeal() == uint8(TypeOfDeal.ShareTransferExt) ||
                        sn.typeOfDeal() == uint8(TypeOfDeal.TagAlong) ||
                        sn.typeOfDeal() == uint8(TypeOfDeal.DragAlong),
                    "IA.createDeal: wrong typeOfDeal"
                );
        } else {
            require(
                sn.classOfDeal() <= _bos.counterOfClasses(),
                "IA.createDeal: class overflow"
            );
            require(
                sn.typeOfDeal() == uint8(TypeOfDeal.CapitalIncrease) ||
                    sn.typeOfDeal() == uint8(TypeOfDeal.PreEmptive),
                "IA.createDeal: wrong typeOfDeal"
            );
        }

        _deals[0].unitPrice++;

        uint16 seq = uint16(_deals[0].unitPrice);

        Deal storage deal = _deals[seq];

        deal.sn = sn;
        deal.shareNumber = shareNumber;

        _dealsList.add(sn);

        if (finalized()) {
            if (
                shareNumber > bytes32(0) &&
                sn.typeOfDeal() != uint8(TypeOfDeal.DragAlong) &&
                sn.typeOfDeal() != uint8(TypeOfDeal.FreeGift)
            ) addBlank(shareNumber.shareholder(), seq);
            addBlank(sn.buyerOfDeal(), seq);
        } else {
            if (shareNumber > bytes32(0))
                addBlank(shareNumber.shareholder(), 0);
            addBlank(sn.buyerOfDeal(), 0);
        }

        emit CreateDeal(sn, shareNumber);

        return sn;
    }

    function setTypeOfIA(uint8 t) external onlyPending onlyAttorney {
        _deals[0].state = t;
        emit SetTypeOfIA(t);
    }

    function updateDeal(
        uint16 seq,
        uint32 unitPrice,
        uint64 paid,
        uint64 par,
        uint32 closingDate
    )
        external
        dealExist(seq)
        attorneyOrKeeper(uint8(TitleOfKeepers.SHAKeeper))
    {
        require(par != 0, "par is ZERO");
        require(par >= paid, "paid overflow");
        require(closingDate > block.number, "closingDate shall be future");

        Deal storage deal = _deals[seq];

        deal.unitPrice = unitPrice;
        deal.par = par;
        deal.paid = paid;
        deal.closingDate = closingDate;

        emit UpdateDeal(deal.sn, unitPrice, paid, par, closingDate);
    }

    function delDeal(uint16 seq)
        external
        onlyPending
        dealExist(seq)
        onlyAttorney
    {
        Deal storage deal = _deals[seq];

        bytes32 sn = deal.sn;

        if (sn.ssnOfDeal() != 0) {
            removeBlank(deal.shareNumber.shareholder(), seq);
        }

        removeBlank(sn.buyerOfDeal(), seq);

        delete _deals[seq];
        _dealsList.remove(sn);

        emit DelDeal(sn);
    }

    function lockDealSubject(uint16 seq)
        external
        dealExist(seq)
        returns (bool flag)
    {
        require(
            _gk.isKeeper(uint8(TitleOfKeepers.BOAKeeper), msg.sender) ||
                _gk.isKeeper(uint8(TitleOfKeepers.SHAKeeper), msg.sender),
            "IA.lockDealSubject: caller has no access right"
        );

        Deal storage deal = _deals[seq];
        if (deal.state == uint8(StateOfDeal.Drafting)) {
            deal.state = uint8(StateOfDeal.Locked);
            flag = true;
            emit LockDealSubject(deal.sn);
        }
    }

    function releaseDealSubject(uint16 seq)
        external
        onlyDK
        dealExist(seq)
        returns (bool flag)
    {
        Deal storage deal = _deals[seq];
        if (deal.state >= uint8(StateOfDeal.Locked)) {
            deal.state = uint8(StateOfDeal.Drafting);
            flag = true;
            emit ReleaseDealSubject(deal.sn);
        }
    }

    function clearDealCP(
        uint16 seq,
        bytes32 hashLock,
        uint32 closingDate
    ) external onlyDK dealExist(seq) {
        Deal storage deal = _deals[seq];

        require(
            uint32(block.timestamp) < closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            closingDate <= closingDeadline(),
            "closingDate LATER than deadline"
        );

        require(deal.state == uint8(StateOfDeal.Locked), "Deal state wrong");

        deal.state = uint8(StateOfDeal.Cleared);

        deal.hashLock = hashLock;

        if (closingDate != 0) deal.closingDate = closingDate;

        emit ClearDealCP(deal.sn, deal.state, hashLock, deal.closingDate);
    }

    function closeDeal(uint16 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDK
    {
        Deal storage deal = _deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        require(
            block.timestamp + 15 minutes <= deal.closingDate,
            "MISSED closing date"
        );

        deal.state = uint8(StateOfDeal.Closed);

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(uint16 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDK
    {
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
            deal.state == uint8(StateOfDeal.Cleared),
            "wrong state of Deal"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.state = uint8(StateOfDeal.Terminated);

        emit RevokeDeal(deal.sn, hashKey);
    }

    function takeGift(uint16 seq)
        external
        onlyKeeper(uint8(TitleOfKeepers.SHAKeeper))
    {
        Deal storage deal = _deals[seq];

        require(
            deal.sn.typeOfDeal() == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            _deals[deal.sn.preSeqOfDeal()].state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.unitPrice == 0, "unitPrice is not zero");

        require(deal.state == uint8(StateOfDeal.Locked), "wrong state");

        deal.state = uint8(StateOfDeal.Closed);

        emit CloseDeal(deal.sn, "0");
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function typeOfIA() external view returns (uint8) {
        return _deals[0].state;
    }

    function isDeal(uint16 seq) external view returns (bool) {
        return _dealsList.contains(_deals[seq].sn);
    }

    function counterOfDeals() external view returns (uint16) {
        return uint16(_deals[0].unitPrice);
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
        paid = deal.paid;
        par = deal.par;
        state = deal.state;
        hashLock = deal.hashLock;
    }

    function unitPriceOfDeal(uint16 seq)
        external
        view
        dealExist(seq)
        returns (uint32)
    {
        return _deals[seq].unitPrice;
    }

    function closingDateOfDeal(uint16 seq)
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
