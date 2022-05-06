/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface ITagAlong {
    function createTag(
        uint16 drager,
        uint8 triggerType,
        bool basedOnPar,
        uint256 threshold,
        bool proRata
    ) external;

    function addFollower(uint16 drager, uint16 follower) external;

    function removeFollower(uint16 drager, uint16 follower) external;

    function delTag(uint16 drager) external;

    // ################
    // ##  查询接口  ##
    // ################

    function tagRule(uint16 drager) external view returns (bytes32);

    function isDrager(uint16 drager) external view returns (bool);

    function isFollower(uint16 drager, uint16 follower)
        external
        view
        returns (bool);

    function isRightholder(address dragerAddr, address followerAddr)
        external
        view
        returns (bool);

    function followers(uint16 drager) external view returns (uint16[]);

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) external view returns (bool);

    function isExempted(address ia, bytes32 sn) external view returns (bool);
}
