/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IAdminSetting {
    // ##################
    // ##   Event      ##
    // ##################

    event Init(address indexed admin, address indexed book);

    event TakeoverAdmin(address indexed admin);

    event AbandonAdmin();

    event SetBackup(address indexed backup);

    event SetBookeeper(address indexed bookeeper);

    // ##################
    // ##   设置端口   ##
    // ##################

    function init(address admin, address bookeeper) external;

    function setBackup(address backup) external;

    function takeoverAdmin() external;

    function abandonAdmin() external;

    function setBookkeeper(address bookeeper) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() external view returns (address);

    function getBackup() external view returns (address);

    function getBookeeper() external view returns (address);
}
