/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IVotingRules {
    // ################
    // ##   写接口   ##
    // ################

    function setRule(
        uint8 typeOfRule,
        uint ratioHead,
        uint ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy
    ) external;

    function setCommonRules(uint8 votingDays, bool basedOnParValue) external;

    // ################
    // ##  查询接口  ##
    // ################

    function votingDays() external view returns (uint8);

    function basedOnParValue() external view returns (bool);

    function rules(uint8 typeOfRule) external view returns (bytes32);
}
