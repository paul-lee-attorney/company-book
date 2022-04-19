/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

contract AdminSetting {
    address private _admin;

    address private _backupAdmin;

    address private _generalKeeper;

    address private _backupKeeper;

    mapping(address => bool) private _keepers;

    // ##################
    // ##   Event      ##
    // ##################

    event Init(address indexed admin, address indexed bookeeper);

    event SetBackupAdmin(address indexed backupAdmin);

    event TakeoverAdmin(address indexed admin);

    event AbandonAdmin();

    event SetBackupKeeper(address indexed backupKeeper);

    event TakeoverBookeeper(address indexed backupKeeper);

    event AppointSubKeeper(address indexed subKeeper);

    event RemoveSubKeeper(address indexed subKeeper);

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier adminOrKeeper() {
        require(
            _keepers[msg.sender] || msg.sender == _admin,
            "NOT bookeeper or admin"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "NOT Admin");
        _;
    }

    modifier onlyKeeper() {
        require(_keepers[msg.sender], "NOT a keeper");
        _;
    }

    modifier onlyGeneralKeeper() {
        require(msg.sender == _generalKeeper, "NOT a keeper");
        _;
    }

    modifier onceOnly(address add) {
        require(add == address(0), "role has been set already");
        _;
    }

    modifier currentDate(uint256 date) {
        require(
            date >= now - 15 minutes && date <= now + 15 minutes,
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
        onceOnly(_generalKeeper)
    {
        _admin = admin;
        _generalKeeper = bookeeper;
        emit Init(admin, bookeeper);
    }

    function setBackupAdmin(address backup) external onlyAdmin {
        _backupAdmin = backup;
        emit SetBackupAdmin(backup);
    }

    function takeoverAdmin() external {
        require(msg.sender == _backupAdmin, "NOT backup admin");
        _admin = msg.sender;
        emit TakeoverAdmin(_admin);
    }

    function abandonAdmin() external onlyKeeper {
        _admin = address(0);
        _backupAdmin = address(0);
        emit AbandonAdmin();
    }

    function setBackupKeeper(address newKeeper) external onlyGeneralKeeper {
        _backupKeeper = newKeeper;
        emit SetBackupKeeper(newKeeper);
    }

    function takeoverBookeeper() external {
        require(msg.sender == _backupKeeper, "NOT bookeeper");
        _generalKeeper = _backupKeeper;
        emit TakeoverBookeeper(_backupKeeper);
    }

    function appointSubKeeper(address addr) external onlyGeneralKeeper {
        _keepers[addr] = true;
        emit AppointSubKeeper(addr);
    }

    function removeSubKeeper(address addr) external onlyGeneralKeeper {
        require(msg.sender == _generalKeeper, "NOT bookeeper");
        _keepers[addr] = false;
        emit AppointSubKeeper(addr);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() public view returns (address) {
        return _admin;
    }

    function getBackupAdmin() public view returns (address) {
        return _backupAdmin;
    }

    function getGK() public view returns (address) {
        return _generalKeeper;
    }

    function getBackupKeeper() public view returns (address) {
        return _backupKeeper;
    }

    function isKeeper(address acct) public view returns (bool) {
        return _keepers[acct];
    }
}
