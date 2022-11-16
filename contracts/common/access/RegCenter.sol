// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

contract RegCenter is IRegCenter {

    struct User {
        address primeKey;
        address backupKey;
        bool flag;
    }

    // userNo => User
    mapping(uint256 => User) private _users;

    // key => bool
    mapping(address => bool) private _usedKeys;

    // primeKey => userNo
    mapping(address => uint40) private _userNo;

    uint32 private _BLOCKS_PER_HOUR;

    constructor(uint32 blocks_per_hour) {
        _BLOCKS_PER_HOUR = blocks_per_hour;
    }

    // ##################
    // ##    Modifier  ##
    // ##################

    modifier onlyRegKey(address key) {
        require(_usedKeys[key], "RC.onlyRegKey: not registered key");
        _;
    }

    modifier onlyContract() {
        require(_isContract(msg.sender), "RC.onlyContract: not a contract");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser() external {
        require(!_usedKeys[msg.sender], "RC.regUser: already registered");

        _userNo[address(0)]++;

        uint40 seq = _userNo[address(0)];

        _users[seq].primeKey = msg.sender;

        _usedKeys[msg.sender] = true;
        _userNo[msg.sender] = seq;

        emit RegUser(seq, msg.sender);
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size > 0;
    }

    function setBackupKey(uint40 user, address backupKey) external override {
        require(backupKey != address(0), "RC.setBackupKey: zero key");
        require(!_usedKeys[backupKey], "RC.setBackupKey: used key");

        User storage u = _users[user];

        require(msg.sender == u.primeKey, "RC.setBackupKey: wrong primeKey");
        require(
            !_isContract(msg.sender),
            "RC.setBackupKey: msgSender shall not be a contract"
        );

        require(!u.flag, "RC.setBackupKey: already set backup key");

        u.flag = true;

        u.backupKey = backupKey;
        _usedKeys[backupKey] = true;

        emit SetBackupKey(user, backupKey);
    }

    function replacePrimeKey(uint40 user) external {
        User storage u = _users[user];

        require(
            msg.sender == u.backupKey,
            "RC.replacePrimeKey: wrong backupKey"
        );

        delete _userNo[u.primeKey];
        _userNo[u.backupKey] = user;

        u.primeKey = u.backupKey;
        u.backupKey = address(0);

        emit ReplacePrimeKey(user, u.primeKey);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function counterOfUsers() external view returns (uint40) {
        return _userNo[address(0)];
    }

    function blocksPerHour() external view returns (uint32) {
        return _BLOCKS_PER_HOUR;
    }

    function primeKey(uint40 user) external view returns (address) {
        return _users[user].primeKey;
    }

    function isContract(uint40 user) external view returns (bool) {
        return _isContract(_users[user].primeKey);
    }

    function isUser(address key) external view returns (bool) {
        return key != address(0) && _userNo[key] > 0;
    }

    function checkID(uint40 user, address key)
        external
        view
        onlyRegKey(key)
        returns (bool)
    {
        require(user > 0, "RC.checkID: zero user");
        require(user <= _userNo[address(0)], "RC.checkID: user overflow");

        return key == _users[user].primeKey;
    }

    function userNo(address key)
        external
        view
        onlyRegKey(key)
        returns (uint40)
    {
        return _userNo[key];
    }
}
