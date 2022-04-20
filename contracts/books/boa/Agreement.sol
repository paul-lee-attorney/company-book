/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/config/BOSSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/SNFactory.sol";
import "../../common/lib/serialNumber/DealSNParser.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "../../common/components/SigPage.sol";

contract Agreement is BOSSetting, SigPage {
    using SNFactory for bytes;
    using SNFactory for bytes32;
    using DealSNParser for bytes32;
    using ShareSNParser for bytes32;
    using ArrayUtils for bytes32[];

    /* struct sn{
        uint8 class; 1
        uint8 typeOfDeal; 1   // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-RT(replaced sales to against voter)
        uint16 sequence; 2
        address buyer; 20
        uint16 shortShareNumber; 6
        uint16 preSequence;
} */

    struct Deal {
        bytes32 sn;
        uint256 unitPrice;
        uint256 parValue;
        uint256 paidPar;
        uint32 closingDate;
        uint8 state; // 0-pending 1-cleared 2-closed 3-revoked
        bytes32 hashLock;
    }

    // party address => parValue
    // mapping(address => uint256) public parToSell;

    // party address => parValue
    // mapping(address => uint256) public parToBuy;

    // sequence => Deal
    mapping(uint16 => Deal) private _deals;

    // sequence => exist?
    mapping(uint16 => bool) public isDeal;

    bytes32[] private _dealsList;

    uint16 public counterOfDeals;

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    // uint8 public typeOfIA;

    //##################
    //##    Event     ##
    //##################

    event CreateDeal(
        bytes32 indexed sn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    );

    event UpdateDeal(
        bytes32 indexed sn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    );

    event SplitDeal(
        bytes32 indexed ssn,
        bytes32 indexed extSN,
        uint256 parValue,
        uint256 paidPar
    );

    event RestoreDeal(bytes32 indexed orgSN, bytes32 indexed splitedSN);

    event DelDeal(bytes32 indexed sn);

    // event SetTypeOfIA(uint8 _typeOfIA);

    event ClearDealCP(
        bytes32 indexed sn,
        uint8 state,
        bytes32 hashLock,
        uint32 closingDate
    );

    event CloseDeal(bytes32 indexed sn, string hashKey);

    event RevokeDeal(bytes32 indexed sn, string hashKey);

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint16 ssn) {
        require(_deals[ssn].state == 1);
        _;
    }

    modifier dealExist(uint16 ssn) {
        require(isDeal[ssn], "NOT a deal sn");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 class,
        uint8 typeOfDeal,
        uint16 sequence,
        address buyer,
        bytes32 shareNumber,
        uint16 preSSN
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn[1] = bytes1(typeOfDeal);
        _sn = _sn.sequenceToSN(2, sequence);
        _sn = _sn.addrToSN(4, buyer);
        _sn = _sn.bytes32ToSN(24, shareNumber, 1, 6);
        _sn = _sn.sequenceToSN(31, preSSN);

        return _sn.bytesToBytes32();
    }

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        address buyer,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    ) external onlyAttorney {
        require(typeOfDeal > 0 && typeOfDeal < 4, "typeOfDeal over flow");
        require(buyer != address(0), "buyer is ZERO address");

        require(parValue > 0, "parValue is ZERO");
        require(paidPar <= parValue, "paidPar overflow");
        require(closingDate > now, "closingDate shall be future");

        if (typeOfDeal > 1) {
            require(_bos.isShare(shareNumber.short()), "shareNumber not exist");

            require(shareNumber.class() == class, "class NOT correct");

            (, uint256 parValueOfShare, uint256 paidParOfShare, , , , ) = _bos
                .getShare(shareNumber.short());
            require(parValueOfShare >= parValue, "parValue overflow");
            require(paidParOfShare >= paidPar, "paidPar overflow");

            if (typeOfDeal == 3)
                require(_bos.isMember(buyer), "buyer is NOT member");
            if (typeOfDeal == 2)
                require(!_bos.isMember(buyer), "buyer IS member");

            addPartyToDoc(shareNumber.shareholder());
            // parToSell[shareNumber.shareholder()] += parValue;
        } else {
            require(
                shareNumber == bytes32(0),
                "capital increase deal shall ONLY have ZERO shareNumber"
            );
            require(class <= _bos.counterOfClasses(), "class overflow");
        }

        addPartyToDoc(buyer);
        // parToBuy[buyer] += parValue;

        counterOfDeals++;

        bytes32 sn = _createSN(
            class,
            typeOfDeal,
            counterOfDeals,
            buyer,
            shareNumber,
            0
        );

        Deal storage deal = _deals[counterOfDeals];

        deal.sn = sn;
        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = closingDate;

        sn.insertToQue(_dealsList);
        isDeal[counterOfDeals] = true;

        emit CreateDeal(sn, unitPrice, parValue, paidPar, closingDate);
    }

    function delDeal(uint16 ssn) public dealExist(ssn) attorneyOrKeeper {
        // Deal storage deal = _deals[sn];

        bytes32 sn = _deals[ssn].sn;

        if (sn.typeOfDeal() > 1) {
            // address seller = sn.sellerOfDeal();
            removePartyFromDoc(sn.sellerOfDeal(_bos.snList()));
            // parToSell[seller] -= deal.parValue;
        }

        // address buyer = sn.buyerOfDeal();

        removePartyFromDoc(sn.buyerOfDeal());
        // parToBuy[buyer] -= deal.parValue;

        delete _deals[ssn];
        _dealsList.removeByValue(sn);
        isDeal[ssn] = false;

        emit DelDeal(sn);
    }

    function updateDeal(
        uint16 ssn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    ) external onlyAttorney dealExist(ssn) {
        require(parValue > 0, "parValue is ZERO");
        require(paidPar <= parValue, "paidPar overflow");
        require(closingDate > now, "closingDate shall be future");

        Deal storage deal = _deals[ssn];

        bytes32 sn = deal.sn;

        if (sn.typeOfDeal() > 1) {
            (, uint256 parValueOfShare, uint256 paidParOfShare, , , , ) = _bos
                .getShare(sn.shortShareNumberOfDeal());
            require(parValueOfShare >= parValue, "parValue overflow");
            require(paidParOfShare >= paidPar, "paidPar overflow");

            // address seller = sn.sellerOfDeal(_bos.snList());

            // if (parValue != deal.parValue)
            //     parToSell[seller] =
            //         parToSell[seller] +
            //         parValue -
            //         deal.parValue;
        }

        // if (parValue != deal.parValue) {
        //     address buyer = sn.buyerOfDeal();
        //     parToBuy[buyer] = parToBuy[buyer] + parValue - deal.parValue;
        // }

        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = closingDate;

        emit UpdateDeal(sn, unitPrice, parValue, paidPar, closingDate);
    }

    function clearDealCP(
        uint16 ssn,
        bytes32 hashLock,
        uint32 closingDate
    ) external onlyKeeper dealExist(ssn) {
        Deal storage deal = _deals[ssn];

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

        emit ClearDealCP(deal.sn, deal.state, hashLock, deal.closingDate);
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

        require(now <= deal.closingDate, "MISSED closing date");

        deal.state = 2;

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(uint16 ssn, string hashKey)
        external
        onlyCleared(ssn)
        onlyKeeper
    {
        Deal storage deal = _deals[ssn];

        require(deal.closingDate < now, "NOT reached closing date");

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.state = 3;

        bytes32 sn = deal.sn;

        if (sn.typeOfDeal() > 1)
            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), deal.parValue);

        emit RevokeDeal(sn, hashKey);
    }

    function _extendSN(
        bytes32 sn,
        uint16 sequence,
        address buyer
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        for (uint8 i = 0; i < 32; i++) _sn[i] = sn[i];

        _sn[1] = bytes1(4);
        _sn = _sn.sequenceToSN(2, sequence);
        _sn = _sn.addrToSN(4, buyer);
        _sn = _sn.sequenceToSN(31, sn.sequenceOfDeal());

        return _sn.bytesToBytes32();
    }

    function splitDeal(
        uint16 ssn,
        address buyer,
        uint256 parValue,
        uint256 paidPar
    ) external onlyCleared(ssn) onlyKeeper {
        counterOfDeals++;

        Deal storage deal = _deals[ssn];
        bytes32 sn = deal.sn;

        bytes32 extSN = _extendSN(sn, counterOfDeals, buyer);

        Deal storage deal_1 = _deals[counterOfDeals];

        deal_1.sn = extSN;
        deal_1.unitPrice = deal.unitPrice;

        require(deal.parValue >= parValue, "parValue over flow");
        deal.parValue -= parValue;
        deal_1.parValue = parValue;

        require(deal.paidPar >= paidPar, "paidPar over flow");
        deal.paidPar -= paidPar;
        deal_1.paidPar = paidPar;

        deal_1.closingDate = deal.closingDate;

        addPartyToDoc(buyer);

        extSN.insertToQue(_dealsList);
        isDeal[counterOfDeals] = true;

        emit SplitDeal(sn, extSN, parValue, paidPar);
    }

    function restoreDeal(uint16 ssn) external onlyKeeper {
        Deal storage deal = _deals[ssn];
        Deal storage orgDeal = _deals[deal.sn.preSNOfDeal()];

        orgDeal.parValue += deal.parValue;
        orgDeal.paidPar += deal.paidPar;

        emit RestoreDeal(orgDeal.sn, deal.sn);

        removePartyFromDoc(deal.sn.buyerOfDeal());
        delDeal(ssn);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function getDeal(uint16 ssn)
        external
        view
        dealExist(ssn)
        returns (
            bytes32 sn,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            uint32 closingDate,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        )
    {
        Deal storage deal = _deals[ssn];

        sn = deal.sn;
        unitPrice = deal.unitPrice;
        parValue = deal.parValue;
        paidPar = deal.paidPar;
        closingDate = deal.closingDate;
        state = deal.state;
        hashLock = deal.hashLock;
    }

    function dealsList() external view returns (bytes32[]) {
        return _dealsList;
    }
}
