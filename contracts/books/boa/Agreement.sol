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
    using DealSNParser for bytes32;
    using ShareSNParser for bytes32;
    using ArrayUtils for bytes32[];

    /* struct sn{
        uint16 sequence; 2
        uint8 typeOfDeal; 1   // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-RT(replaced sales to against voter)
        bytes6 shortShareNumber; 6
        uint8 class; 1
        address buyer; 20
} */

    struct Deal {
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

    // sn => Deal
    mapping(bytes32 => Deal) private _deals;

    // sn => exist?
    mapping(bytes32 => bool) public isDeal;

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
        bytes32 indexed sn,
        bytes32 indexed extSN,
        uint256 parValue,
        uint256 paidPar
    );

    event DelDeal(bytes32 indexed sn);

    event SetTypeOfIA(uint8 _typeOfIA);

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

    modifier onlyCleared(bytes32 sn) {
        require(_deals[sn].state == 1);
        _;
    }

    modifier dealExist(bytes32 sn) {
        require(isDeal[sn], "NOT a deal sn");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint16 sequence,
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        address buyer
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, sequence);
        _sn[2] = bytes1(typeOfDeal);
        _sn = _sn.bytes32ToSN(3, shareNumber, 1, 6);
        _sn[9] = bytes1(class);
        _sn = _sn.addrToSN(10, buyer);

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
            require(_bos.isShare(shareNumber), "shareNumber not exist");

            require(shareNumber.class() == class, "class NOT correct");

            (uint256 parValueOfShare, uint256 paidParOfShare, , , , ) = _bos
                .getShare(shareNumber);
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
            counterOfDeals,
            typeOfDeal,
            shareNumber,
            class,
            buyer
        );

        _dealsList.push(sn);

        Deal storage deal = _deals[sn];

        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = closingDate;

        emit CreateDeal(sn, unitPrice, parValue, paidPar, closingDate);
    }

    function delDeal(bytes32 sn) external onlyAttorney dealExist(sn) {
        // Deal storage deal = _deals[sn];

        if (sn.typeOfDeal() > 1) {
            // address seller = sn.seller();
            removePartyFromDoc(sn.seller(_bos.snList()));
            // parToSell[seller] -= deal.parValue;
        }

        // address buyer = sn.buyer();

        removePartyFromDoc(sn.buyer());
        // parToBuy[buyer] -= deal.parValue;

        delete _deals[sn];
        _dealsList.removeByValue(sn);

        emit DelDeal(sn);
    }

    function updateDeal(
        bytes32 sn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    ) external onlyAttorney dealExist(sn) {
        require(parValue > 0, "parValue is ZERO");
        require(paidPar <= parValue, "paidPar overflow");
        require(closingDate > now, "closingDate shall be future");

        Deal storage deal = _deals[sn];

        if (sn.typeOfDeal() > 1) {
            (uint256 parValueOfShare, uint256 paidParOfShare, , , , ) = _bos
                .getShare(sn.shareNumber(_bos.snList()));
            require(parValueOfShare >= parValue, "parValue overflow");
            require(paidParOfShare >= paidPar, "paidPar overflow");

            // address seller = sn.seller(_bos.snList());

            // if (parValue != deal.parValue)
            //     parToSell[seller] =
            //         parToSell[seller] +
            //         parValue -
            //         deal.parValue;
        }

        // if (parValue != deal.parValue) {
        //     address buyer = sn.buyer();
        //     parToBuy[buyer] = parToBuy[buyer] + parValue - deal.parValue;
        // }

        deal.unitPrice = unitPrice;
        deal.parValue = parValue;
        deal.paidPar = paidPar;
        deal.closingDate = closingDate;

        emit UpdateDeal(sn, unitPrice, parValue, paidPar, closingDate);
    }

    function clearDealCP(
        bytes32 sn,
        bytes32 hashLock,
        uint32 closingDate
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

    function closeDeal(bytes32 sn, string hashKey)
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

    function revokeDeal(bytes32 sn, string hashKey)
        external
        onlyCleared(sn)
        onlyBookeeper
    {
        Deal storage deal = _deals[sn];

        require(deal.closingDate < now, "NOT reached closing date");

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.state = 3;

        if (sn.typeOfDeal() > 1)
            _bos.increaseCleanPar(sn.shareNumber(_bos.snList()), deal.parValue);

        emit RevokeDeal(sn, hashKey);
    }

    function _extendSN(
        bytes32 sn,
        uint16 sequence,
        address buyer
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        for (uint8 i = 0; i < 32; i++) _sn[i] = sn[i];

        _sn = _sn.sequenceToSN(0, sequence);
        _sn[2] = bytes1(4);
        _sn = _sn.addrToSN(10, buyer);

        return _sn.bytesToBytes32();
    }

    function splitDeal(
        bytes32 sn,
        address buyer,
        uint256 parValue,
        uint256 paidPar
    ) external onlyCleared(sn) onlyBookeeper {
        counterOfDeals++;

        bytes32 extSN = _extendSN(sn, counterOfDeals, buyer);

        _dealsList.push(extSN);

        Deal storage deal = _deals[sn];
        Deal storage deal_1 = _deals[extSN];

        deal_1.unitPrice = deal.unitPrice;

        require(deal.parValue >= parValue, "parValue over flow");
        deal.parValue -= parValue;
        deal_1.parValue = parValue;

        require(deal.paidPar >= paidPar, "paidPar over flow");
        deal.paidPar -= paidPar;
        deal_1.paidPar = paidPar;

        deal_1.closingDate = deal.closingDate;

        addPartyToDoc(buyer);

        emit SplitDeal(sn, extSN, parValue, paidPar);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function getDeal(bytes32 sn)
        external
        view
        dealExist(sn)
        returns (
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            uint32 closingDate,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        )
    {
        Deal storage deal = _deals[sn];

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

    // function parToSell(address acct) external view returns (uint256 output) {
    //     uint256 len = _dealsList.length;
    //     for (uint256 i = 0; i < len; i++)
    //         if (_dealsList[i].seller(_bos.snList()) == acct)
    //             output += _deals[_dealsList[i]].parValue;
    // }

    // function parToBuy(address acct) external view returns (uint256 output) {
    //     uint256 len = _dealsList.length;
    //     for (uint256 i = 0; i < len; i++)
    //         if (_dealsList[i].buyer() == acct)
    //             output += _deals[_dealsList[i]].parValue;
    // }

    // // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    // function typeOfIA() external view returns (uint8 output) {
    //     uint256 len = _dealsList.length;
    //     uint8[3] memory signal;
    //     for (uint256 i = 0; i < len; i++) {
    //         uint8 typeOfDeal = _dealsList[i].typeOfDeal();
    //         signal[typeOfDeal - 1] = typeOfDeal;
    //     }
    //     // 协议类别计算
    //     uint8 sumOfSignal = signal[0] + signal[1] + signal[2];
    //     output = sumOfSignal == 3 ? signal[2] == 0 ? 7 : 3 : sumOfSignal;
    // }
}
