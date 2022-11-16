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

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser() external;

    function setBackupKey(uint40 user, address backupKey) external;

    function replacePrimeKey(uint40 user) external;

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

}
