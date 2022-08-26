/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// import "../../common/lib/SNFactory.sol";
// import "../../common/lib/SNParser.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/IASetting.sol";

// import "./IInvestmentAgreement.sol";
import "./IFirstRefusalDeals.sol";

contract FirstRefusalDeals is IFirstRefusalDeals, IASetting, BOSSetting {
    // using SNFactory for bytes;
    // using SNParser for bytes32;

    struct Claim {
        uint64 weight; // FR rightholder's voting weight
        uint64 ratio;
    }

    struct FRDeals {
        uint64 sumOfWeight;
        mapping(uint16 => Claim) claims;
    }

    // ==== FRDeals ====
    // seq => FRDeals
    mapping(uint16 => FRDeals) private _frDeals;

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 seqOfOD,
        uint16 seqOfFR,
        uint40 acct
    ) external onlyManager(1) dealExist(seqOfOD) {
        uint64 weight = _bos.voteInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");

        if (_frDeals[seqOfOD].claims[seqOfFR].weight == 0) {
            _frDeals[seqOfOD].sumOfWeight += weight;
            _frDeals[seqOfOD].claims[seqOfFR].weight = weight;

            emit ExecFirstRefusal(seqOfOD, seqOfFR, acct);
        }
    }

    function acceptFirstRefusal(uint16 seqOfOD, uint16 seqOfFR)
        external
        onlyManager(1)
        dealExist(seqOfOD)
        returns (uint64 ratio)
    {
        uint64 sumOfWeight = _frDeals[seqOfOD].sumOfWeight;
        require(sumOfWeight > 0, "FRDeals not found");

        uint64 weight = _frDeals[seqOfOD].claims[seqOfFR].weight;
        require(weight > 0, "FRClaim not found");

        ratio = _frDeals[seqOfOD].claims[seqOfFR].ratio;

        if (ratio == 0) {
            ratio = (weight * 10000) / sumOfWeight;
            _frDeals[seqOfOD].claims[seqOfFR].ratio = ratio;
        }

        emit AcceptFirstRefusal(seqOfOD, seqOfFR, ratio);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function sumOfWeight(uint16 seqOfOD) external view returns (uint64) {
        return _frDeals[seqOfOD].sumOfWeight;
    }

    function isTargetDeal(uint16 seqOfOD) external view returns (bool) {
        return _frDeals[seqOfOD].sumOfWeight > 0;
    }

    function isFRDeal(uint16 seqOfOD, uint16 seqOfFR)
        external
        view
        returns (bool)
    {
        return _frDeals[seqOfOD].claims[seqOfFR].weight > 0;
    }

    function weightOfFR(uint16 seqOfOD, uint16 seqOfFR)
        external
        view
        returns (uint64)
    {
        return _frDeals[seqOfOD].claims[seqOfFR].weight;
    }

    function ratioOfFR(uint16 seqOfOD, uint16 seqOfFR)
        external
        view
        returns (uint64)
    {
        return _frDeals[seqOfOD].claims[seqOfFR].ratio;
    }
}