/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IAdminSetting.sol";

contract AdminSetting is IAdminSetting {
    address internal _admin;

    address internal _backup;

    address internal _bookeeper;

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier adminOrBookeeper() {
        require(
            msg.sender == _bookeeper || msg.sender == _admin,
            "NOT bookeeper or admin"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "NOT Admin");
        _;
    }

    modifier onlyBackup() {
        require(msg.sender == _backup, "NOT backup admin");
        _;
    }

    modifier onlyBookeeper() {
        require(msg.sender == _bookeeper, "NOT bookeeper");
        _;
    }

    modifier onceOnly(address add) {
        require(add == address(0), "role has been set already");
        _;
    }

    modifier onlyStakeholders() {
        address sender = msg.sender;
        require(
            sender == _admin || sender == _bookeeper,
            "NOT interested party"
        );
        _;
    }

    modifier currentDate(uint256 date) {
        require(
            date >= now - 2 hours && date <= now + 2 hours,
            "NOT a current date"
        );
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(address admin, address bookeeper)
        public
        onceOnly(_admin)
        onceOnly(_bookeeper)
    {
        _admin = admin;
        _bookeeper = bookeeper;
        emit Init(admin, bookeeper);
    }

    function setBackup(address backup) external onlyAdmin {
        _backup = backup;
        emit SetBackup(backup);
    }

    function takeoverAdmin() external onlyBackup {
        _admin = msg.sender;
        emit TakeoverAdmin(_admin);
    }

    function abandonAdmin() external onlyBookeeper {
        _admin = address(0);
        _backup = address(0);
        emit AbandonAdmin();
    }

    function setBookeeper(address bookeeper) external onlyBookeeper {
        _bookeeper = bookeeper;
        emit SetBookeeper(bookeeper);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() public view returns (address) {
        return _admin;
    }

    function getBackup() public view returns (address) {
        return _backup;
    }

    function getBookeeper() public view returns (address) {
        return _bookeeper;
    }
}
