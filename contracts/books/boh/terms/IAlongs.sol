/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAlongs {
    // ################
    // ##   Event    ##
    // ################

    event SetLink(uint16 indexed dragerGroup, bytes32 rule);

    event AddFollower(uint16 indexed dragerGroup, uint16 followerGroup);

    event RemoveFollower(uint16 indexed dragerGroup, uint16 followerGroup);

    event DelLink(uint16 indexed dragerGroup);

    // ################
    // ##   Write    ##
    // ################

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

    function delLink(uint16 drager) external;

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint16 drager) external view returns (bytes32);

    function isDrager(uint16 drager) external view returns (bool);

    function isFollower(uint16 drager, uint16 follower)
        external
        view
        returns (bool);

    function isLinked(uint40 usrDrager, uint40 usrFollower)
        external
        view
        returns (bool);

    function dragers() external view returns (uint16[]);

    function followers(uint16 drager) external view returns (uint16[]);

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view returns (bool);
}
