/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAlongs {
    // ################
    // ##   Event    ##
    // ################

    event SetLink(uint40 indexed drager, bytes32 rule);

    event AddFollower(uint40 indexed drager, uint40 follower);

    event RemoveFollower(uint40 indexed drager, uint40 follower);

    event DelLink(uint40 indexed drager);

    // ################
    // ##   Write    ##
    // ################

    function createLink(
        uint40 drager,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) external;

    function addFollower(uint40 drager, uint40 follower) external;

    function removeFollower(uint40 drager, uint40 follower) external;

    function delLink(uint40 drager) external;

    // ###############
    // ##  查询接口  ##
    // ###############

    function linkRule(uint40 drager) external view returns (bytes32);

    function isDrager(uint40 drager) external view returns (bool);

    function repOf(uint40 drager) external view returns(uint40);

    function isLinked(uint40 drager, uint40 follower)
        external
        view
        returns (bool);

    function dragers() external view returns (uint40[]);

    function followers(uint40 drager) external view returns (uint40[]);

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view returns (bool);
}
