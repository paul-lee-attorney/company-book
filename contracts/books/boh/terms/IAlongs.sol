/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAlongs {
    function createLink(
        uint16 drager,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) external;

    function addFollower(uint16 drager, uint16 follower) external;

    function removeFollower(uint16 drager, uint16 follower) external;

    function delTag(uint16 drager) external;

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint16 drager) external view returns (bytes32);

    function isDrager(uint16 drager) external view returns (bool);

    function isFollower(uint16 drager, uint16 follower)
        external
        view
        returns (bool);

    function isLinked(address dragerAddr, address followerAddr)
        external
        view
        returns (bool);

    function followers(uint16 drager) external view returns (uint16[]);

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) external view returns (bool);

    function isExempted(address ia, bytes32 sn) external view returns (bool);

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view returns (bool);
}