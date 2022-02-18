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

    event SetBookkeeper(address indexed bookkeeper);

    // ##################
    // ##   设置端口   ##
    // ##################

    function init(address admin, address bookkeeper) external;

    function setBackup(address backup) external;

    function takeoverAdmin() external;

    function abandonAdmin() external;

    function setBookkeeper(address bookkeeper) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() external view returns (address);

    function getBackup() external view returns (address);

    function getBookkeeper() external view returns (address);
}
