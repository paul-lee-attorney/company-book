/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./InvestmentAgreement.sol";

import "../../common/lib/ObjsRepo.sol";

contract FirstRefusalToolKits is InvestmentAgreement {
    using ObjsRepo for ObjsRepo.TimeLine;

    struct Record {
        uint16 ssn; // FR sequence number
        uint256 weight; // FR rightholder's voting weight
    }

    // dealSN => counterOfFR
    mapping(uint16 => uint16) private _counterOfFR;

    // dealSN => accumulatedWeight
    mapping(uint16 => uint256) private _sumOfWeight;

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

    event AcceptFR(bytes32 indexed sn, uint40 sender);

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 ssn,
        uint40 acct,
        // uint32 execDate,
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
            targetDeal.sn.sequence()
        );

        _counterOfFR[ssn]++;

        if (_counterOfFR[ssn] == 1)
            targetDeal.states.setState(uint8(EnumsRepo.StateOfDeal.Terminated));

        uint256 weight = _bos.voteInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");

        Record storage record = _records[ssn][_counterOfFR[ssn]];

        record.ssn = snOfFR.sequence();
        record.weight = weight;

        _sumOfWeight[ssn] += weight;

        _updateFRDeals(ssn, _counterOfFR[ssn]);

        lockDealSubject(snOfFR.sequence());

        signDeal(ssn, acct, sigHash);

        return snOfFR;
    }

    function _updateFRDeals(uint16 ssn, uint16 len) private {
        Deal storage targetDeal = _deals[ssn];

        while (len > 0) {
            Record storage record = _records[ssn][len];

            uint256 parValue = (targetDeal.parValue * record.weight) /
                _sumOfWeight[ssn];

            uint256 paidPar = (targetDeal.paidPar * record.weight) /
                _sumOfWeight[ssn];

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
        uint40 acct,
        // uint32 acceptDate,
        bytes32 sigHash
    ) external onlyDirectKeeper dealExist(ssn) {
        uint16 len = _counterOfFR[ssn];

        while (len > 0) {
            uint16 frSSN = _records[ssn][len].ssn;
            signDeal(frSSN, acct, sigHash);
            len--;
        }

        emit AcceptFR(_deals[ssn].sn, acct);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function counterOfFR(uint16 ssn) external view onlyUser returns (uint16) {
        return _counterOfFR[ssn];
    }

    function sumOfWeight(uint16 ssn) external view onlyUser returns (uint256) {
        return _sumOfWeight[ssn];
    }

    function isTargetDeal(uint16 ssn) external view onlyUser returns (bool) {
        return _counterOfFR[ssn] > 0;
    }

    function frDeals(uint16 ssn) external view onlyUser returns (uint16[]) {
        require(_counterOfFR[ssn] > 0, "not a target deal of FR");

        uint16 len = _counterOfFR[ssn];

        uint16[] memory deals = new uint16[](len - 1);

        while (len > 0) {
            deals[len - 1] = _records[ssn][len].ssn;
            len--;
        }

        return deals;
    }
}
