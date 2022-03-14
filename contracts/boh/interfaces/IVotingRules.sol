/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../lib/ArrayUtils.sol";
// import "../lib/ArrayUtils.sol";

import "../../config/DraftSetting.sol";
// import "../common/AdminSetting.sol";
import "../../common/EnumsRepo.sol";

// import "../action/DealsRepo.sol";

// import "../interfaces/IAgreement.sol";

// import "../interfaces/IMotion.sol";

// import "./interfaces/ILockUp.sol";
// import "./interfaces/ITerm.sol";

interface IVotingRules {
    // ################
    // ##   写接口   ##
    // ################

    function setRule(
        uint8 typeOfIA,
        uint256 ratio,
        uint8 typeOfRatio,
        bool onlyVoted,
        bool impliedConsent,
        bool againstShallBuy,
        uint8 reconsiderDays
    ) external;

    function setCommonRules(uint8 votingDays, bool basedOnParValue) external;

    // ################
    // ##  查询接口  ##
    // ################

    function votingDays() external view returns (uint8);

    function basedOnParValue() external view returns (bool);

    function getRule(uint8 typeOfIA)
        external
        view
        returns (
            uint256 ratioHead,
            uint256 ratioAmount,
            bool onlyVoted,
            bool impliedConsent,
            bool againstShallBuy,
            uint8 reconsiderDays
        );
}
