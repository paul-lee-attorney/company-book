/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/IASetting.sol";

import "./IInvestmentAgreement.sol";
import "./IFirstRefusalDeals.sol";

contract FirstRefusalDeals is IFirstRefusalDeals, IASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;

    struct Claim {
        uint64 weight; // FR rightholder's voting weight
        uint64 ratio;
    }

    struct FRDeals {
        uint64 sumOfWeight;
        mapping(uint16 => Claim) claims;
    }

    // ==== FRDeals ====

    mapping(uint16 => FRDeals) private _frDeals;

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 ssnOfOD,
        uint16 ssnOfFR,
        uint40 acct
    ) external onlyManager(1) dealExist(ssnOfOD) {
        uint64 weight = _bos.voteInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");

        if (_frDeals[ssnOfOD].claims[ssnOfFR].weight == 0) {
            _frDeals[ssnOfOD].sumOfWeight += weight;
            _frDeals[ssnOfOD].claims[ssnOfFR].weight = weight;

            emit ExecFirstRefusal(ssnOfOD, ssnOfFR, acct);
        }
    }

    function acceptFirstRefusal(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        onlyManager(1)
        dealExist(ssnOfOD)
        returns (uint64 ratio)
    {
        uint64 sumOfWeight = _frDeals[ssnOfOD].sumOfWeight;
        require(sumOfWeight > 0, "FRDeals not found");

        uint64 weight = _frDeals[ssnOfOD].claims[ssnOfFR].weight;
        require(weight > 0, "FRClaim not found");

        ratio = _frDeals[ssnOfOD].claims[ssnOfFR].ratio;

        if (ratio == 0) {
            ratio = (weight * 10000) / sumOfWeight;
            _frDeals[ssnOfOD].claims[ssnOfFR].ratio = ratio;
        }

        emit AcceptFirstRefusal(ssnOfOD, ssnOfFR, ratio);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function sumOfWeight(uint16 ssnOfOD) external view returns (uint64) {
        return _frDeals[ssnOfOD].sumOfWeight;
    }

    function isTargetDeal(uint16 ssnOfOD) external view returns (bool) {
        return _frDeals[ssnOfOD].sumOfWeight > 0;
    }

    function isFRDeal(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        view
        returns (bool)
    {
        return _frDeals[ssnOfOD].claims[ssnOfFR].weight > 0;
    }

    function weightOfFR(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        view
        returns (uint64)
    {
        return _frDeals[ssnOfOD].claims[ssnOfFR].weight;
    }

    function ratioOfFR(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        view
        returns (uint64)
    {
        return _frDeals[ssnOfOD].claims[ssnOfFR].ratio;
    }
}
