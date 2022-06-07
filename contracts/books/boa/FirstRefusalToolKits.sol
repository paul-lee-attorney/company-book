/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./InvestmentAgreement.sol";

import "../../common/lib/UserGroup.sol";
import "../../common/lib/SequenceList.sol";
import "../../common/lib/Timeline.sol";

contract FirstRefusalToolKits is InvestmentAgreement {
    using UserGroup for UserGroup.Group;
    using SequenceList for SequenceList.List;
    using Timeline for Timeline.Line;

    struct Record {
        uint16 ssn; // FR sequence number
        uint256 weight; // FR rightholder's voting weight
    }

    // dealSN => counterOfFR
    mapping(uint16 => uint16) public counterOfFR;

    // dealSN => accumulatedWeight
    mapping(uint16 => uint256) public sumOfWeight;

    // dealSN => counterOfFR => ssn
    mapping(uint16 => mapping(uint16 => Record)) private _records;

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
    ) external onlyKeeper dealExist(ssn) returns (bytes32) {
        Deal storage targetDeal = _deals[ssn];

        bytes32 snOfFR = createDeal(
            targetDeal.shareNumber == bytes32(0)
                ? uint8(EnumsRepo.TypeOfDeal.PreEmptive)
                : uint8(EnumsRepo.TypeOfDeal.FirstRefusal),
            targetDeal.shareNumber,
            targetDeal.sn.classOfDeal(),
            acct,
            _bos.groupNo(acct),
            targetDeal.sn.sequenceOfDeal()
        );

        counterOfFR[ssn]++;

        if (counterOfFR[ssn] == 1)
            targetDeal.states.setState(
                uint8(EnumsRepo.StateOfDeal.Terminated),
                execDate
            );

        uint256 weight = basedOnPar
            ? _bos.parInHand(acct)
            : _bos.paidInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");

        Record storage record = _records[ssn][counterOfFR[ssn]];

        record.ssn = snOfFR.sequenceOfDeal();
        record.weight = weight;

        sumOfWeight[ssn] += weight;

        established = false;

        _updateFRDeals(ssn, counterOfFR[ssn]);

        signDeal(ssn, acct, execDate, sigHash);

        return snOfFR;
    }

    function _updateFRDeals(uint16 ssn, uint16 len) private {
        Deal storage targetDeal = _deals[ssn];

        while (len > 0) {
            Record storage record = _records[ssn][len];

            uint256 parValue = (targetDeal.parValue * record.weight) /
                sumOfWeight[ssn];

            uint256 paidPar = (targetDeal.paidPar * record.weight) /
                sumOfWeight[ssn];

            updateDeal(
                record.ssn,
                targetDeal.unitPrice,
                parValue,
                paidPar,
                targetDeal.closingDate
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
            uint16 frSSN = _records[ssn][len].ssn;
            signDeal(frSSN, acct, acceptDate, sigHash);
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
            deals[len - 1] = _records[ssn][len].ssn;
            len--;
        }

        return deals;
    }
}
