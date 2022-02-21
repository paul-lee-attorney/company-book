/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";

import "../lib/SafeMath.sol";

// import "../lib/ArrayUtils.sol";

import "../common/SigPage.sol";

contract Agreement is BOSSetting, SigPage {
    using SafeMath for uint256;
    using SafeMath for uint8;
    // using ArrayUtils for uint256[];

    struct Deal {
        uint256 shareNumber;
        uint8 class;
        address seller;
        address buyer;
        uint256 unitPrice;
        uint256 parValue;
        uint256 paidInAmount;
        uint256 closingDate;
        uint8 typeOfDeal; // 1-CI 2-ST(to 3rd) 3-ST(internal)
        uint8 state; // 0-pending 1-cleared 2-closed 3-terminated
        bytes32 hashLock;
    }

    // uint256[] private _sharesToSell;
    // // shareNumber => parValue
    // mapping(uint256 => uint256) private _parToSplit;

    // party address => amount
    mapping(address => uint256) private _parToSell;
    // party address => amount
    mapping(address => uint256) private _parToBuy;

    // sn => Deal
    mapping(uint8 => Deal) private _deals;
    uint8 private _qtyOfDeals;

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    uint8 private _typeOfIA;

    // uint256 private _closingDeadline;

    // // 0-pending 1-finalized 2-signed 3-submitted 4-closed 5-terminated
    // uint8 private _state;

    //##################
    //##    Event     ##
    //##################

    event SetDeal(
        uint8 indexed sn,
        uint256 indexed shareNumber,
        uint8 class,
        address seller,
        address buyer,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 closingDate,
        uint8 typeOfDeal
    );

    event DelDeal(uint8 indexed sn);

    event SetTypeOfIA(uint8 typeOfIA);

    event ClearDealCP(
        uint8 indexed sn,
        uint8 state,
        bytes32 hashLock,
        uint256 closingDate
    );

    event CloseDeal(uint8 indexed sn, bytes hashKey);

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint8 sn) {
        require(sn < _qtyOfDeals);
        require(_deals[sn].state == 1);
        _;
    }

    modifier dealExist(uint8 sn) {
        require(sn < _qtyOfDeals);
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setDeal(
        uint8 sn,
        uint256 shareNumber,
        uint8 class,
        address seller,
        address buyer,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 closingDate
    ) external onlyAttorney {
        require(sn <= _qtyOfDeals, "sn overflow");

        require(buyer != address(0), "buyer has zero address");
        require(parValue > 0, "parValue is Zero");
        require(paidInAmount <= parValue, "paidInAmount overflow");
        require(
            closingDate == 0 || closingDate > now,
            "closingDate shall be future"
        );

        if (shareNumber != 0) {
            require(_bos.shareExist(shareNumber), "shareNumber not exist");

            (
                address shareholder,
                ,
                uint256 parValueOfShare,
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 paidInAmountOfShare,

            ) = _bos.getShare(shareNumber);
            require(shareholder == seller, "seller is not shareholder");
            require(parValueOfShare >= parValue, "parValue overflow");
            require(
                paidInAmountOfShare >= paidInAmount,
                "paidInAmount overflow"
            );

            // addPartyToDoc(seller);
        } else {
            require(class <= _bos.counterOfClass(), "class overflow");
        }

        Deal storage deal = _deals[sn];

        deal.shareNumber = shareNumber;
        deal.class = class;
        deal.seller = seller;
        deal.buyer = buyer;
        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidInAmount = paidInAmount;
        deal.closingDate = closingDate == 0 ? now : closingDate;
        deal.typeOfDeal = shareNumber == 0 ? 1 : _bos.isMember(buyer) ? 3 : 2;

        if (sn == _qtyOfDeals) _qtyOfDeals = _qtyOfDeals.add8(1);

        // addPartyToDoc(buyer);

        emit SetDeal(
            sn,
            shareNumber,
            class,
            seller,
            buyer,
            unitPrice,
            parValue,
            paidInAmount,
            closingDate,
            deal.typeOfDeal
        );
    }

    function delDeal(uint8 sn) external onlyAttorney dealExist(sn) {
        // removePartyFromDoc(_deals[sn].buyer);

        // if (_deals[sn].typeOfDeal > 1) removePartyFromDoc(_deals[sn].seller);

        delete _deals[sn];
        _qtyOfDeals--;

        emit DelDeal(sn);
    }

    function finalizeIA()
        external
        onlyAttorney
        onlyForDraft
        beforeClosingStartpoint
    {
        uint8 i = 0;
        bool allMembersIn;
        uint8[3] memory signal;

        for (; i < _qtyOfDeals; i++) {
            Deal storage deal = _deals[i];

            // 交易类别统计
            signal[deal.typeOfDeal - 1] = deal.typeOfDeal;

            // 股转交易
            if (deal.typeOfDeal > 1) {
                // _sharesToSell.addValue(deal.shareNumber);
                // _parToSplit[deal.shareNumber] = _parToSplit[deal.shareNumber]
                //     .add(deal.parValue);

                addPartyToDoc(deal.seller);
                _parToSell[deal.seller] += deal.parValue;

                // 增资交易
            } else if (!allMembersIn) {
                address[] memory members = _bos.membersList();
                for (uint8 j = 0; j < members.length; j++)
                    addPartyToDoc(members[j]);
                allMembersIn = true;
            }

            addPartyToDoc(deal.buyer);
            _parToBuy[deal.buyer] = _parToBuy[deal.buyer].add(deal.parValue);
        }

        // // 股转溢出判断
        // for (i = 0; i < _sharesToSell.length; i++) {
        //     (, , uint256 parValueOfShare, , , , , , , , ) = _bos.getShare(
        //         _sharesToSell[i]
        //     );
        //     if (parValueOfShare < _parToSplit[_sharesToSell[i]]) return false;
        // }

        // 协议类别计算
        uint8 sumOfSignal = signal[0] + signal[1] + signal[2];
        _typeOfIA = sumOfSignal == 3 ? signal[2] == 0 ? 7 : 3 : sumOfSignal;

        emit SetTypeOfIA(_typeOfIA);

        circulateDoc();
    }

    function clearDealCP(
        uint8 sn,
        bytes32 hashLock,
        uint256 closingDate
    )
        external
        onlyForSubmitted
        onlyBookeeper
        beforeClosingStartpoint
        dealExist(sn)
    {
        Deal storage deal = _deals[sn];

        // require(
        //     deal.typeOfDeal == 1 || deal.seller == tx.origin,
        //     "仅 卖方 或 合约创设人 有权操作"
        // );

        require(
            closingDate == 0 || deal.closingDate <= closingDate,
            "closingDate can ONLY be extended"
        );

        require(
            closingDate <= getClosingDeadline(),
            "closingDate later than deadline"
        );

        require(deal.state == 0, "Deal not signed");

        deal.state = 1;
        deal.hashLock = hashLock;
        deal.closingDate = closingDate;

        emit ClearDealCP(sn, 1, hashLock, closingDate);
    }

    function closeDeal(uint8 sn, bytes hashKey)
        external
        onlyForSubmitted
        onlyCleared(sn)
        onlyBookeeper
        beforeClosingDeadline
    {
        Deal storage deal = _deals[sn];
        // require(deal.buyer == tx.origin, "仅 买方 可调用");

        require(deal.hashLock == keccak256(hashKey), "hashKey is wrong");

        require(now <= deal.closingDate, "missed closing date");

        deal.state = 2;

        emit CloseDeal(sn, hashKey);
    }

    // function closeIA() external onlyBookeeper onlyForSubmitted {
    //     bool flag = true;

    //     for (uint8 i = 0; i < _qtyOfDeals; i++) {
    //         if (_deals[i].state != 2) {
    //             flag = false;
    //             break;
    //         }
    //     }

    //     closeDoc(flag);
    // }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    // function getSharesToSell()
    //     public
    //     view
    //     onlyConcernedEntity
    //     returns (uint256[] shares)
    // {
    //     shares = _sharesToSell;
    // }

    // function getParToSplit(uint256 shareNumber)
    //     public
    //     view
    //     onlyConcernedEntity
    //     returns (uint256 parValue)
    // {
    //     parValue = _parToSplit[shareNumber];
    // }

    function getParToSell(address acct)
        external
        view
        returns (
            // onlyConcernedEntity
            uint256 parValue
        )
    {
        parValue = _parToSell[acct];
    }

    function getParToBuy(address acct)
        external
        view
        returns (
            // onlyConcernedEntity
            uint256 parValue
        )
    {
        parValue = _parToBuy[acct];
    }

    function getDeal(uint8 sn)
        external
        view
        dealExist(sn)
        onlyConcernedEntity
        returns (
            uint256 shareNumber,
            uint8 class,
            address seller,
            address buyer,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidInAmount,
            uint256 closingDate,
            uint8 typeOfDeal, // 1-CI 2-ST(to 3rd) 3-ST(internal)
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        )
    {
        shareNumber = _deals[sn].shareNumber;
        class = _deals[sn].class;
        seller = _deals[sn].seller;
        buyer = _deals[sn].buyer;
        unitPrice = _deals[sn].unitPrice;
        parValue = _deals[sn].parValue;
        paidInAmount = _deals[sn].paidInAmount;
        closingDate = _deals[sn].closingDate;
        typeOfDeal = _deals[sn].typeOfDeal;
        state = _deals[sn].state;
        hashLock = _deals[sn].hashLock;
    }

    function getQtyOfDeals() external view onlyConcernedEntity returns (uint8) {
        return _qtyOfDeals;
    }

    function getTypeOfIA() external view onlyConcernedEntity returns (uint8) {
        return _typeOfIA;
    }
}
