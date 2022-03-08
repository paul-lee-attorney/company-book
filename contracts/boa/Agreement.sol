/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";

import "../lib/SafeMath.sol";

import "../common/SigPage.sol";

contract Agreement is BOSSetting, SigPage {
    using SafeMath for uint256;
    using SafeMath for uint8;

    struct Deal {
        uint256 shareNumber;
        address seller;
        address buyer;
        uint256 unitPrice;
        uint256 parValue;
        uint256 paidInAmount;
        uint256 closingDate;
        uint8 class;
        uint8 typeOfDeal; // 1-CI 2-ST(to 3rd) 3-ST(internal)
        uint8 state; // 0-pending 1-cleared 2-closed 3-revoked
        bytes32 hashLock;
    }

    // party address => amount
    mapping(address => uint256) public parToSell;
    // party address => amount
    mapping(address => uint256) public parToBuy;

    // sn => Deal
    mapping(uint8 => Deal) private _deals;

    uint8 public qtyOfDeals;

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    uint8 public typeOfIA;

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
        uint256 closingDate
    );

    event DelDeal(uint8 indexed sn);

    event SetTypeOfIA(uint8 _typeOfIA);

    event ClearDealCP(
        uint8 indexed sn,
        uint8 state,
        bytes32 hashLock,
        uint256 closingDate
    );

    event CloseDeal(uint8 indexed sn, string hashKey);

    event RevokeDeal(uint8 indexed sn, string hashKey);

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint8 sn) {
        require(_deals[sn].state == 1);
        _;
    }

    modifier dealExist(uint8 sn) {
        require(sn < qtyOfDeals);
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
        require(sn <= qtyOfDeals, "SN overflow");

        require(buyer != address(0), "buyer is ZERO address");
        require(parValue > 0, "parValue is ZERO");
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
                uint256 paidInAmountOfShare,
                ,
                ,
                ,

            ) = _bos.getShare(shareNumber);
            require(shareholder == seller, "seller is not shareholder");
            require(parValueOfShare >= parValue, "parValue overflow");
            require(
                paidInAmountOfShare >= paidInAmount,
                "paidInAmount overflow"
            );
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

        if (sn == qtyOfDeals) qtyOfDeals = qtyOfDeals.add8(1);

        emit SetDeal(
            sn,
            shareNumber,
            class,
            seller,
            buyer,
            unitPrice,
            parValue,
            paidInAmount,
            deal.closingDate
        );
    }

    function delDeal(uint8 sn) external onlyAttorney dealExist(sn) {
        delete _deals[sn];
        qtyOfDeals--;

        emit DelDeal(sn);
    }

    function finalizeIA() external onlyAttorney {
        uint8 i = 0;
        bool allMembersIn;
        uint8[3] memory signal;

        for (; i < qtyOfDeals; i++) {
            Deal storage deal = _deals[i];

            // 交易类别统计
            signal[deal.typeOfDeal - 1] = deal.typeOfDeal;

            // 股转交易
            if (deal.typeOfDeal > 1) {
                addPartyToDoc(deal.seller);
                parToSell[deal.seller] += deal.parValue;

                // 增资交易
            } else if (!allMembersIn) {
                address[] memory members = _bos.membersList();
                for (uint8 j = 0; j < members.length; j++)
                    addPartyToDoc(members[j]);
                allMembersIn = true;
            }

            addPartyToDoc(deal.buyer);
            parToBuy[deal.buyer] = parToBuy[deal.buyer].add(deal.parValue);
        }

        // 协议类别计算
        uint8 sumOfSignal = signal[0] + signal[1] + signal[2];
        typeOfIA = sumOfSignal == 3 ? signal[2] == 0 ? 7 : 3 : sumOfSignal;

        emit SetTypeOfIA(typeOfIA);
    }

    function clearDealCP(
        uint8 sn,
        bytes32 hashLock,
        uint256 closingDate
    ) external onlyBookeeper dealExist(sn) {
        Deal storage deal = _deals[sn];

        require(
            closingDate == 0 || now < closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            closingDate <= closingDeadline,
            "closingDate LATER than deadline"
        );

        require(deal.state == 0, "Deal state wrong");

        deal.state = 1;
        deal.hashLock = hashLock;
        if (closingDate > 0) deal.closingDate = closingDate;

        emit ClearDealCP(sn, 1, hashLock, deal.closingDate);
    }

    function closeDeal(uint8 sn, string hashKey)
        external
        onlyCleared(sn)
        onlyBookeeper
    {
        Deal storage deal = _deals[sn];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        require(now <= deal.closingDate, "MISSED closing date");

        deal.state = 2;

        emit CloseDeal(sn, hashKey);
    }

    function revokeDeal(uint8 sn, string hashKey)
        external
        onlyCleared(sn)
        onlyBookeeper
    {
        Deal storage deal = _deals[sn];

        require(deal.closingDate > now, "NOT reached closing date");

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.state = 3;

        emit RevokeDeal(sn, hashKey);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function getDeal(uint8 sn)
        external
        view
        dealExist(sn)
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
}
