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

    event ResetBackupKeyFlag(uint40 indexed userNo);

    event SetManager(uint40 cont, uint8 title, uint40 acct);

    event GrantRole(uint40 cont, bytes32 role, uint40 acct);

    event RevokeRole(uint40 cont, bytes32 role, uint40 acct);

    event RenounceRole(uint40 cont, bytes32 role, uint40 acct);

    event AbandonRole(uint40 cont, bytes32 role);

    event SetRoleAdmin(uint40 cont, bytes32 role, uint40 acct);

    event CreateEntity(
        uint40 indexed entity,
        uint8 typeOfEntity,
        uint8 roleOfUser
    );

    event JoinEntity(uint40 indexed entity, uint40 user, uint8 roleOfUser);

    event QuitEntity(uint40 indexed entity, uint40 user, uint8 roleOfUser);

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser(uint8 roleOfUser, uint40 entity) external returns (uint40);

    function quitEntity(uint8 roleOfUser) external;

    function setBackupKey(uint40 user, address backupKey) external;

    function replacePrimeKey(uint40 user) external;

    // ==== EquityInvest ====

    // function investIn(
    //     uint40 usrInvestor,
    //     uint64 parValue,
    //     bool checkRingStruct
    // ) external returns (bool);

    // function exitOut(uint40 usrInvestor) external returns (bool);

    // function updateParValue(uint40 usrInvestor, uint64 parValue)
    //     external
    //     returns (bool);

    // ==== Director ====

    // function takePosition(uint40 usrCandy, uint8 title) external returns (bool);

    // function quitPosition(uint40 usrDirector) external returns (bool);

    // function changeTitle(uint40 usrDirector, uint8 title)
    //     external
    //     returns (bool);

    // ==== Roles ====

    function setManager(uint8 title, address acct) external;

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

    function userNo(address key) external returns (uint40);

    // ==== Entity ====
    function isEntity(uint40 entity) external view returns (bool);

    function entityNo(address acct) external view returns (uint40);

    function memberOfEntity(uint40 entity, uint8 role)
        external
        view
        returns (uint40);

    function isKeeper(address caller) external view returns (bool);

    // ==== Element ====

    // function getEntity(uint40 entity)
    //     external
    //     view
    //     returns (
    //         uint8,
    //         uint40,
    //         uint88,
    //         uint16,
    //         uint88,
    //         uint16
    //     );

    // function getConnection(uint88 con)
    //     external
    //     view
    //     returns (
    //         uint88,
    //         uint88,
    //         uint64
    //     );

    // function isRoot(uint40 entity) external view returns (bool);

    // function isLeaf(uint40 entity) external view returns (bool);

    // ==== Graph ====

    // function getUpBranches(uint40 origin)
    //     external
    //     view
    //     returns (uint40[] entities, uint88[] connections);

    // function getDownBranches(uint40 origin)
    //     external
    //     view
    //     returns (uint40[] entities, uint88[] connections);

    // function getRoundGraph(uint40 origin)
    //     external
    //     view
    //     returns (uint40[] entities, uint88[] connections);

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
