/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IRegCenter {
    // ##################
    // ##    Event     ##
    // ##################

    event RegUser(uint40 indexed userNo, address primeKey);

    event SetBackupKey(uint40 indexed userNo, address backupKey);

    event ReplacePrimeKey(uint40 indexed userNo, address newKey);

    event ResetBackupKeyFlag(uint40 indexed userNo);

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser(uint8 roleOfUser, uint40 entity) external returns (uint40);

    function quitEntity(uint8 roleOfUser) external;

    function setBackupKey(uint40 userNo, address backupKey) external;

    function replacePrimeKey(uint40 userNo) external;

    // ==== EquityInvest ====

    function investIn(
        uint40 usrInvestor,
        uint64 parValue,
        bool checkRingStruct
    ) external returns (bool);

    function exitOut(uint40 usrInvestor) external returns (bool);

    function updateParValue(uint40 usrInvestor, uint64 parValue)
        external
        returns (bool);

    // ==== Director ====

    function takePosition(uint40 usrCandy, uint8 title) external returns (bool);

    function quitPosition(uint40 usrDirector) external returns (bool);

    function changeTitle(uint40 usrDirector, uint8 title)
        external
        returns (bool);

    // ##################
    // ##   查询端口   ##
    // ##################

    function counterOfUsers() external view returns (uint40);

    function blocksPerHour() external view returns (uint32);

    function primeKey(uint40 userNo) external view returns (address);

    function isContract(uint40 userNo) external view returns (bool);

    function isUser(address key) external view returns (bool);

    function checkID(uint40 userNo, address key) external returns (bool);

    function userNo(address key) external returns (uint40);

    // ==== Entity ====

    function entityNo(uint40 user) external view returns (uint40);

    function memberOfEntity(uint40 entity, uint8 role)
        external
        view
        returns (uint40);

    // ==== Element ====

    function getEntity(uint40 entity)
        external
        view
        returns (
            uint8,
            uint40,
            uint88,
            uint16,
            uint88,
            uint16
        );

    function getConnection(uint88 con)
        external
        view
        returns (
            uint88,
            uint88,
            uint64
        );

    function isRoot(uint40 entity) external view returns (bool);

    function isLeaf(uint40 entity) external view returns (bool);

    // ==== Graph ====

    function getUpBranches(uint40 origin)
        external
        returns (uint40[] entities, uint88[] connections);

    function getDownBranches(uint40 origin)
        external
        returns (uint40[] entities, uint88[] connections);

    function getRoundGraph(uint40 origin)
        external
        returns (uint40[] entities, uint88[] connections);
}
