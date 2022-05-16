/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/ArrayUtils.sol";

contract AdminSetting {
    using ArrayUtils for address[];

    address private _admin;

    address private _backupAdmin;

    address private _directKeeper;

    address private _backupKeeper;

    mapping(address => bool) private _isKeeper;
    address[] private _keepers;

    mapping(address => bool) private _isReader;
    address[] private _readers;

    // ##################
    // ##   Event      ##
    // ##################

    event Init(address indexed admin, address indexed bookeeper);

    event SetBackupAdmin(address indexed backupAdmin);

    event TakeoverAdmin(address indexed admin);

    event AbandonAdmin();

    event SetBackupKeeper(address indexed backupKeeper);

    event TakeoverBookeeper(address indexed backupKeeper);

    event GrantKeeper(address indexed subKeeper);

    event RevokeKeeper(address indexed subKeeper);

    event GrantReader(address indexed granter, address indexed reader);

    event RevokeReader(address indexed reader);

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier adminOrKeeper() {
        require(
            _isKeeper[msg.sender] || msg.sender == _admin,
            "not KEEPER or ADMIN"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "not ADMIN");
        _;
    }

    modifier onlyKeeper() {
        require(_isKeeper[msg.sender], "not KEEPER");
        _;
    }

    modifier onlyDirectKeeper() {
        require(msg.sender == _directKeeper, "not GeneralKeeper");
        _;
    }

    modifier onlyReader() {
        require(_isReader[msg.sender], "not READER");
        _;
    }

    modifier onceOnly(address addr) {
        require(addr == address(0), "already set");
        _;
    }

    modifier currentDate(uint256 date) {
        require(
            date >= now - 15 minutes && date <= now + 15 minutes,
            "not a current date"
        );
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(address admin, address bookeeper)
        public
        onceOnly(_admin)
        onceOnly(_directKeeper)
    {
        _admin = admin;
        _directKeeper = bookeeper;

        _isKeeper[bookeeper] = true;
        _keepers.push(bookeeper);

        _isReader[bookeeper] = true;
        _readers.push(bookeeper);

        _isReader[admin] = true;
        _readers.push(admin);

        emit Init(admin, bookeeper);
    }

    function setBackupAdmin(address backup) external onlyAdmin {
        _backupAdmin = backup;
        emit SetBackupAdmin(backup);
    }

    function takeoverAdmin() external {
        require(msg.sender == _backupAdmin, "not backup admin");
        _admin = msg.sender;
        emit TakeoverAdmin(_admin);
    }

    function abandonAdmin() external onlyDirectKeeper {
        _admin = address(0);
        _backupAdmin = address(0);
        emit AbandonAdmin();
    }

    function setBackupKeeper(address newKeeper) external onlyDirectKeeper {
        _backupKeeper = newKeeper;
        emit SetBackupKeeper(newKeeper);
    }

    function takeoverBookeeper() external {
        require(msg.sender == _backupKeeper, "not backup keeper");
        _directKeeper = _backupKeeper;
        emit TakeoverBookeeper(_backupKeeper);
    }

    function grantKeeper(address addr) external onlyDirectKeeper {
        require(!_isKeeper[addr], "already grant KEEPER");

        _isKeeper[addr] = true;
        _keepers.push(addr);

        grantReader(addr);

        emit GrantKeeper(addr);
    }

    function revokeKeeper(address addr) external onlyDirectKeeper {
        require(_isKeeper[addr], "not a KEEPER");

        delete _isKeeper[addr];
        _keepers.removeByValue(addr);

        revokeReader(addr);

        emit RevokeKeeper(addr);
    }

    function grantReader(address acct) public onlyReader {
        require(!_isReader[acct], "already grant as READER");

        _isReader[acct] = true;
        _readers.push(acct);

        emit GrantReader(msg.sender, acct);
    }

    function revokeReader(address acct) public onlyKeeper {
        require(_isReader[acct], "not a READER");

        delete _isReader[acct];
        _readers.removeByValue(acct);

        emit RevokeReader(acct);
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

    function getKeeper() public view returns (address) {
        return _directKeeper;
    }

    function getBackupKeeper() public view returns (address) {
        return _backupKeeper;
    }

    function isKeeper(address acct) public view returns (bool) {
        return _isKeeper[acct];
    }

    function keepers() public view returns (address[]) {
        return _keepers;
    }

    function isReader(address acct) public view returns (bool) {
        return _isReader[acct];
    }

    function readers() public view returns (address[]) {
        return _readers;
    }
}
