/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

import "../../common/components/SigPage.sol";

contract Agreement is BOSSetting, SigPage {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ArrayUtils for bytes32[];

    /* struct sn{
        uint8 class; 1
        uint8 typeOfDeal; 1   // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-TagAlong 5-DragAlong 6-FirstRefusal
        uint16 sequence; 2
        uint32 buyer; 4
        uint16 group; 2
        bytes6 shortShareNumber; 6
        uint16 preSN; 2
    } 
    */

    struct Deal {
        bytes32 sn;
        bytes32 shareNumber;
        uint256 unitPrice;
        uint256 parValue;
        uint256 paidPar;
        uint32 closingDate;
        uint8 state; // 0-drafting 1-cleared 2-closed 3-revoked 4-suspend
        bytes32 hashLock;
    }

    // sequence => Deal
    mapping(uint16 => Deal) internal _deals;

    // sequence => exist?
    mapping(uint16 => bool) public isDeal;

    bytes32[] internal _dealsList;

    uint16 public counterOfDeals;

    //##################
    //##    Event     ##
    //##################

    event CreateDeal(bytes32 indexed sn, bytes32 shareNumber);

    event CreateAlongDeal(bytes32 indexed sn);

    event AddFirstRefusalBuyer(bytes32 indexed sn, address buyer);

    event UpdateDeal(
        bytes32 indexed sn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    );

    event DelDeal(bytes32 indexed sn);

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
        uint32 buyer,
        uint16 group,
        bytes32 shareNumber,
        uint16 preSSN
    ) internal pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn[1] = bytes1(typeOfDeal);
        _sn = _sn.sequenceToSN(2, sequence);
        _sn = _sn.dateToSN(4, buyer);
        _sn = _sn.sequenceToSN(8, group);
        _sn = _sn.bytes32ToSN(10, shareNumber, 1, 6);
        _sn = _sn.sequenceToSN(16, preSSN);

        return _sn.bytesToBytes32();
    }

    function createDeal(
        bytes32 shareNumber,
        uint8 class,
        uint32 buyer,
        uint16 group
    ) external onlyPending onlyAttorney returns (bytes32) {
        require(buyer != 0, "buyer is ZERO address");
        require(group > 0, "ZERO group");

        uint8 typeOfDeal = 1;

        if (shareNumber > bytes32(0)) {
            require(_bos.isShare(shareNumber.short()), "shareNumber not exist");
            require(shareNumber.class() == class, "class NOT correct");

            if (_bos.isMember(buyer)) typeOfDeal = 3;
            else typeOfDeal = 2;

            addPartyToDoc(shareNumber.shareholder());
        } else {
            require(class <= _bos.counterOfClasses(), "class overflow");
        }

        addPartyToDoc(buyer);

        counterOfDeals++;

        bytes32 sn = _createSN(
            class,
            typeOfDeal,
            counterOfDeals,
            buyer,
            group,
            shareNumber,
            0
        );

        Deal storage deal = _deals[counterOfDeals];

        deal.sn = sn;
        deal.shareNumber = shareNumber;
        // deal.unitPrice = unitPrice;
        // deal.parValue = parValue;
        // deal.paidPar = paidPar;
        // deal.closingDate = closingDate;

        _dealsList.push(sn);
        isDeal[counterOfDeals] = true;

        emit CreateDeal(sn, shareNumber);

        return sn;
    }

    function updateDeal(
        uint16 ssn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    ) external onlyPending dealExist(ssn) onlyAttorney {
        require(parValue > 0, "parValue is ZERO");
        require(parValue >= paidPar, "paidPar overflow");
        require(closingDate > now + 15 minutes, "closingDate shall be future");

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

        if (sn.typeOfDeal() > 1) {
            removePartyFromDoc(deal.shareNumber.shareholder());
        }

        removePartyFromDoc(sn.buyerOfDeal());

        delete _deals[ssn];
        _dealsList.removeByValue(sn);
        isDeal[ssn] = false;

        emit DelDeal(sn);
    }

    function kill() external onlyDirectKeeper {
        selfdestruct(getDirectKeeper());
    }

    function clearDealCP(
        uint16 ssn,
        bytes32 hashLock,
        uint32 closingDate
    ) external onlyKeeper dealExist(ssn) {
        Deal storage deal = _deals[ssn];

        require(
            closingDate == 0 || now - 15 minutes < closingDate,
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

        require(now - 15 minutes <= deal.closingDate, "MISSED closing date");

        deal.state = 2;

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(uint16 ssn, string hashKey)
        external
        onlyCleared(ssn)
        onlyKeeper
    {
        Deal storage deal = _deals[ssn];

        require(
            deal.closingDate < now + 15 minutes,
            "NOT reached closing date"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.state = 3;

        emit RevokeDeal(deal.sn, hashKey);
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

    function shareNumberOfDeal(uint16 ssn)
        external
        view
        dealExist(ssn)
        returns (bytes32)
    {
        return _deals[ssn].shareNumber;
    }

    function dealsList() external view returns (bytes32[]) {
        return _dealsList;
    }
}
