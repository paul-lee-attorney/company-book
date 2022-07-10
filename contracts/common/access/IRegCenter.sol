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

    function regUser(uint8 roleOfUser, uint40 entity) external;

    function setBackupKey(uint40 userNo, address backupKey) external;

    function replacePrimaryKey(uint40 userNo) external;

    function investIn(uint40 usrInvestor, uint16 parRatio) external;

    function takePosition(uint40 usrCandy, uint8 title) external;

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
}
