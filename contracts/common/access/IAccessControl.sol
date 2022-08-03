/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAccessControl {
    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        address indexed owner,
        address indexed directKeeper,
        address regCenter
    );

    event RegThisContract(uint40 userNo);

    event SetManager(uint8 title, address originator, address acct);

    event GrantRole(bytes32 role, uint40 acct);

    event RevokeRole(bytes32 role, uint40 acct);

    event RenounceRole(bytes32 role, uint40 acct);

    event AbandonRole(bytes32 role);

    event SetRoleAdmin(bytes32 role, uint40 acct);

    event LockContents();

    event QuitEntity(uint8 roleOfUser);

    event CopyRoleTo(bytes32 role, address to);

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        uint8 roleOfUser,
        uint40 entity
    ) external;

    // function regThisContract(uint8 roleOfUser, uint40 entity) external;

    function setManager(uint8 title, address acct) external;

    function grantRole(bytes32 role, uint40 acct) external;

    function revokeRole(bytes32 role, uint40 acct) external;

    function renounceRole(bytes32 role, uint40 acct) external;

    function abandonRole(bytes32 role) external;

    function setRoleAdmin(bytes32 role, uint40 acct) external;

    function lockContents() external;

    function quitEntity(uint8 roleOfUser) external;

    function copyRoleTo(bytes32 role, address to) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getManager(uint8 title) external view returns (uint40);

    function getManagerKey(uint8 title) external view returns (address);

    function finalized() external view returns (bool);
}
