// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IAccessControl {
    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        uint40 owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    );

    event SetDirectKeeper(address keeper);

    event SetManager(uint8 title, uint40 acct);

    // event SetRoleAdmin(bytes32 role, uint40 acct);

    // event GrantRole(bytes32 role, uint40 acct);

    // event RevokeRole(bytes32 role, uint40 acct);

    // event RenounceRole(bytes32 role, uint40 acct);

    // event AbandonRole(bytes32 role);

    event LockContents();

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        uint40 owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external;

    function setDirectKeeper(address keeper) external;

    function setManager(uint8 title, uint40 acct) external;

    function grantRole(bytes32 role, uint40 acct) external;

    function revokeRole(bytes32 role, uint40 acct) external;

    function renounceRole(bytes32 role) external;

    function abandonRole(bytes32 role) external;

    function setRoleAdmin(bytes32 role, uint40 acct) external;

    function lockContents() external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getManager(uint8 title) external view returns (uint40);

    function getBookeeper() external view returns (address);

    function getManagerKey(uint8 title) external view returns (address);

    function finalized() external view returns (bool);

    function hasRole(bytes32 role, uint40 acct) external view returns (bool);
}
