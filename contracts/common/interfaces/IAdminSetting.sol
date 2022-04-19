/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IAdminSetting {
    // ##################
    // ##   设置端口   ##
    // ##################

    function init(address admin, address bookeeper) external;

    function setBackupAdmin(address backup) external;

    function takeoverAdmin() external;

    function abandonAdmin() external;

    function setBackupKeeper(address backup) external;

    function takeoverBookeeper() external;

    function appointSubKeeper(address addr) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() external view returns (address);

    function getBackupAdmin() external view returns (address);

    function getGK() external view returns (address);

    function getBackupKeeper() public view returns (address);

    function isKeeper(address acct) public view returns (bool);
}
