/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/Timeline.sol";
import "../../common/lib/EnumsRepo.sol";

import "../../common/components/SigPage.sol";

contract InvestmentAgreement is BOSSetting, SigPage {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ArrayUtils for bytes32[];
    using Timeline for Timeline.Line;

    /* struct sn{
        uint8 class; 1
        uint8 typeOfDeal; 1   // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-TagAlong 5-FirstRefusal 6-Gift 
        uint16 sequence; 2
        uint32 buyer; 4
        uint16 group; 2
        bytes6 shortShareNumber; 6
        uint16 preSN; 2
    } 
    */

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
        uint256 unitPrice;
        uint256 parValue;
        uint256 paidPar;
        uint32 closingDate;
        Timeline.Line states; // 0-drafting 1-cleared 2-closed 3-revoked 4-suspend
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

    event LockDealSubject(bytes32 indexed sn);

    event ReleaseDealSubject(bytes32 indexed sn);

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
        require(
            _deals[ssn].states.currentState == uint8(StateOfDeal.Cleared),
            "wrong stateOfDeal"
        );
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
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        uint32 buyer,
        uint16 group,
        uint16 preSSN
    ) external onlyPending attorneyOrKeeper returns (bytes32) {
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

            addPartyToDoc(shareNumber.shareholder());
        } else {
            require(class <= _bos.counterOfClasses(), "class overflow");
            require(
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease) ||
                    typeOfDeal == uint8(EnumsRepo.TypeOfDeal.PreEmptive),
                "wrong typeOfDeal"
            );
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
            preSSN
        );

        Deal storage deal = _deals[counterOfDeals];

        deal.sn = sn;
        deal.shareNumber = shareNumber;

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

    function lockDealSubject(uint16 ssn, uint32 lockDate)
        external
        onlyKeeper
        dealExist(ssn)
        currentDate(lockDate)
        returns (bool flag)
    {
        Deal storage deal = _deals[ssn];
        if (deal.states.currentState == uint8(StateOfDeal.Drafting)) {
            deal.states.pushToNextState(lockDate);
            flag = true;
            emit LockDealSubject(deal.sn);
        }
    }

    function releaseDealSubject(uint16 ssn, uint32 releaseDate)
        public
        onlyKeeper
        dealExist(ssn)
        currentDate(releaseDate)
        returns (bool flag)
    {
        Deal storage deal = _deals[ssn];
        if (deal.states.currentState >= uint8(StateOfDeal.Locked)) {
            deal.states.setState(uint8(StateOfDeal.Drafting), releaseDate);
            flag = true;
            emit ReleaseDealSubject(deal.sn);
        }
    }

    function clearDealCP(
        uint16 ssn,
        uint32 sigDate,
        bytes32 hashLock,
        uint32 closingDate
    ) external onlyKeeper currentDate(sigDate) dealExist(ssn) {
        Deal storage deal = _deals[ssn];

        require(
            closingDate == 0 || now - 15 minutes < closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            closingDate <= closingDeadline,
            "closingDate LATER than deadline"
        );

        require(
            deal.states.currentState == uint8(StateOfDeal.Drafting),
            "Deal state wrong"
        );

        deal.states.pushToNextState(sigDate);

        deal.hashLock = hashLock;

        if (closingDate > 0) deal.closingDate = closingDate;

        emit ClearDealCP(
            deal.sn,
            deal.states.currentState,
            hashLock,
            deal.closingDate
        );
    }

    function closeDeal(
        uint16 ssn,
        uint32 sigDate,
        string hashKey
    ) external onlyCleared(ssn) onlyKeeper {
        Deal storage deal = _deals[ssn];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        require(now - 15 minutes <= deal.closingDate, "MISSED closing date");

        deal.states.pushToNextState(sigDate);

        emit CloseDeal(deal.sn, hashKey);
    }

    function revokeDeal(
        uint16 ssn,
        uint32 sigDate,
        string hashKey
    ) external onlyCleared(ssn) onlyKeeper {
        Deal storage deal = _deals[ssn];

        require(
            deal.closingDate < now + 15 minutes,
            "NOT reached closing date"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.states.pushToNextState(sigDate);

        emit RevokeDeal(deal.sn, hashKey);
    }

    function takeGift(
        uint16 ssn,
        uint32 sigDate,
        uint32 caller
    ) external onlyKeeper {
        Deal storage deal = _deals[ssn];

        require(
            deal.closingDate < now + 15 minutes,
            "NOT reached closing date"
        );

        require(deal.sn.typeOfDeal() == 6, "not a gift deal");
        require(deal.unitPrice == 0, "unitPrice is not zero");
        require(caller == deal.sn.buyerOfDeal(), "caller is not buyer");

        require(
            deal.states.currentState == uint8(StateOfDeal.Locked),
            "wrong state"
        );

        deal.states.pushToNextState(sigDate);
        deal.states.pushToNextState(sigDate);

        emit CloseDeal(deal.sn, "0");
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
            uint256 parValue,
            uint256 paidPar,
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
        returns (uint256)
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
        return _dealsList;
    }
}
