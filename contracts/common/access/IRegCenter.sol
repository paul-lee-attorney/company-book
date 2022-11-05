// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IRegCenter {
    // ##################
    // ##    Event     ##
    // ##################

    event RegUser(uint40 indexed userNo, address primeKey);

    event SetBackupKey(uint40 indexed userNo, address backupKey);

    event ReplacePrimeKey(uint40 indexed userNo, address newKey);

    event SetManager(uint40 cont, uint8 title, uint40 acct);

    event GrantRole(uint40 cont, bytes32 role, uint40 acct);

    event RevokeRole(uint40 cont, bytes32 role, uint40 acct);

    event RenounceRole(uint40 cont, bytes32 role, uint40 acct);

    event AbandonRole(uint40 cont, bytes32 role);

    event SetRoleAdmin(uint40 cont, bytes32 role, uint40 acct);

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser() external;

    function setBackupKey(uint40 user, address backupKey) external;

    function replacePrimeKey(uint40 user) external;

    // ==== Roles ====

    function setManager(uint8 title, address addrOfAcct) external;

    function grantRole(
        bytes32 role,
        address addrOfOriginator,
        uint40 acct
    ) external;

    function revokeRole(
        bytes32 role,
        address addrOfOriginator,
        uint40 acct
    ) external;

    function renounceRole(bytes32 role, address addrOfOriginator) external;

    function abandonRole(bytes32 role, address addrOfOriginator) external;

    function setRoleAdmin(
        bytes32 role,
        address addrOfOriginator,
        uint40 acct
    ) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function counterOfUsers() external view returns (uint40);

    function blocksPerHour() external view returns (uint32);

    function primeKey(uint40 user) external view returns (address);

    function isContract(uint40 user) external view returns (bool);

    function isUser(address key) external view returns (bool);

    function checkID(uint40 user, address key) external returns (bool);

    function userNo(address key) external view returns (uint40);

    // ==== Role ====
    function hasRole(bytes32 role, address addrOfOriginator)
        external
        view
        returns (bool);

    function isManager(uint8 title, address addrOfOriginator)
        external
        view
        returns (bool);

    function getManager(uint8 title) external view returns (uint40);

    function getManagerKey(uint8 title) external view returns (address);

    function getManagerOf(uint8 title, uint40 doc)
        external
        view
        returns (uint40);
}
