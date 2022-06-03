/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./InvestmentAgreement.sol";

import "../../common/lib/UserGroup.sol";
import "../../common/lib/SequenceList.sol";
import "../../common/lib/Timeline.sol";

contract InvestmentAgreementWithFirstRefusal is InvestmentAgreement {
    using UserGroup for UserGroup.Group;
    using SequenceList for SequenceList.List;
    using Timeline for Timeline.Line;

    struct FRRecord {
        uint16 frSSN;
        uint256 weight;
    }

    // // sequenceOfDeal => FRRecord
    // mapping(uint16 => FRRecord) private _frNotices;

    // // sequenceOfDeal => bool/list
    // SequenceList.List internal _subjectDeals;

    // dealSN => counterOfFR
    mapping(uint16 => uint16) public counterOfFR;

    // dealSN => accumulatedWeight
    mapping(uint16 => uint256) public sumOfWeight;

    // dealSN => counterOfFR => frSSN
    mapping(uint16 => mapping(uint16 => FRRecord)) private _frRecords;

    //##################
    //##    Event     ##
    //##################

    event CreateFRDeal(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    );

    event UpdateFRDeal(bytes32 indexed sn, uint256 parValue, uint256 paidPar);

    event AcceptFR(bytes32 indexed sn, uint32 sender);

    //##################
    //##   Modifier   ##
    //##################

    // modifier subDealExist(uint16 ssn) {
    //     require(_subjectDeals.isItem(ssn), "NOT be requested for FR");
    //     _;
    // }

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 ssn,
        bool basedOnPar,
        uint32 acct,
        uint32 execDate,
        bytes32 sigHash
    ) external onlyKeeper dealExist(ssn) {
        require(!isInitSigner(acct), "FR requester is an InitSigner");

        counterOfFR[ssn]++;
        counterOfDeals++;

        FRRecord storage record = _frRecords[ssn][counterOfFR[ssn]];
        Deal storage targetDeal = _deals[ssn];
        Deal storage frDeal = _deals[counterOfDeals];

        if (counterOfFR[ssn] == 1)
            targetDeal.states.setState(
                uint8(EnumsRepo.StateOfDeal.Terminated),
                execDate
            );

        uint256 weight = basedOnPar
            ? _bos.parInHand(acct)
            : _bos.paidInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");

        record.weight = weight;
        sumOfWeight[ssn] += weight;

        bytes32 snOfFR = _createSN(
            targetDeal.sn.typeOfDeal(),
            uint8(EnumsRepo.TypeOfDeal.FirstRefusal), // FirstRefusal
            counterOfDeals,
            acct,
            _bos.groupNo(acct),
            targetDeal.shareNumber,
            targetDeal.sn.sequenceOfDeal()
        );

        frDeal.sn = snOfFR;
        frDeal.shareNumber = targetDeal.shareNumber;
        frDeal.unitPrice = targetDeal.unitPrice;
        frDeal.parValue = (targetDeal.parValue * weight) / sumOfWeight[ssn];
        frDeal.paidPar = (targetDeal.paidPar * weight) / sumOfWeight[ssn];
        frDeal.closingDate = targetDeal.closingDate;

        emit CreateFRDeal(
            snOfFR,
            frDeal.shareNumber,
            frDeal.unitPrice,
            frDeal.parValue,
            frDeal.paidPar,
            frDeal.closingDate
        );

        _signatures.addBlank(acct, snOfFR.sequenceOfDeal());
        _signatures.signDeal(acct, snOfFR.sequenceOfDeal(), execDate, sigHash);

        _signatures.addBlank(
            frDeal.shareNumber.shareholder(),
            snOfFR.sequenceOfDeal()
        );

        established = false;

        _updatePrevFRDeal(ssn, counterOfFR[ssn], targetDeal);
    }

    function _updatePrevFRDeal(
        uint16 ssn,
        uint16 len,
        Deal storage targetDeal
    ) private {
        while (len > 1) {
            FRRecord storage prevRecord = _frRecords[ssn][len - 1];
            Deal storage prevFRDeal = _deals[prevRecord.frSSN];

            prevFRDeal.parValue =
                (targetDeal.parValue * prevRecord.weight) /
                sumOfWeight[ssn];
            prevFRDeal.paidPar =
                (targetDeal.paidPar * prevRecord.weight) /
                sumOfWeight[ssn];

            emit UpdateFRDeal(
                prevFRDeal.sn,
                prevFRDeal.parValue,
                prevFRDeal.paidPar
            );

            len--;
        }
    }

    function acceptFR(
        uint16 ssn,
        uint32 acct,
        uint32 acceptDate,
        bytes32 sigHash
    ) external dealExist(ssn) {
        uint16 len = counterOfFR[ssn];

        while (len > 0) {
            uint16 frSSN = _frRecords[ssn][len].frSSN;
            _signatures.signDeal(acct, frSSN, acceptDate, sigHash);
            len--;
        }

        emit AcceptFR(_deals[ssn].sn, acct);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function isTargetDeal(uint16 ssn) public view returns (bool) {
        return counterOfFR[ssn] > 0;
    }

    function frDeals(uint16 ssn) external view returns (uint16[]) {
        require(isTargetDeal(ssn), "not a target deal of FR");

        uint16 len = counterOfFR[ssn];

        uint16[] memory deals = new uint16[](len - 1);

        while (len > 0) {
            deals[len - 1] = _frRecords[ssn][len].frSSN;
            len--;
        }

        return deals;
    }
}
