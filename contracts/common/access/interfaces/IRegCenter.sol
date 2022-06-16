/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IRegCenter {
    function counterOfUsers() external returns (uint40);

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser() external;

    function setBackupKey(uint40 userNo, address backupKey) external;

    function replacePrimaryKey(uint40 userNo) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function isUser(address key) external returns (bool);

    function checkID(uint40 userNo, address key) external returns (bool);

    function userNo(address key) external returns (uint40);
}
