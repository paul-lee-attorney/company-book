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
        address indexed owner,
        address indexed directKeeper,
        address regCenter,
        address generalKeeper
    );

    event LockContents();
    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external;

    function setManager(
        uint8 title,
        address caller,
        address acct
    ) external;

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

    function getManagerKey(uint8 title) external view returns (address);

    function finalized() external view returns (bool);

    function hasRole(address acctAddr, bytes32 role)
        external
        view
        returns (bool);
}
