/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
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

    function grantKeeper(address addr) external;

    function revokeKeeper(address addr) external;

    function grantReader(address addr) external;

    function revokeReader(address addr) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() external view returns (address);

    function getBackupAdmin() external view returns (address);

    function getKeeper() external view returns (address);

    function getBackupKeeper() external view returns (address);

    function isKeeper(address acct) external view returns (bool);

    function keepers() external view returns (address[]);

    function isReader(address acct) external view returns (bool);

    function readers() external view returns (address[]);
}
