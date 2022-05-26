/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

contract RegCenter {
    struct User {
        address primeKey;
        address backupKey;
    }

    // userNo => User
    mapping(uint32 => User) private _users;

    // key => bool
    mapping(address => bool) private _registeredKeys;

    // primeKey => userNo
    mapping(address => uint32) private _userNo;

    uint32 public counterOfUsers;

    // ##################
    // ##    Event     ##
    // ##################

    event RegUser(uint32 indexed userNo, address primeKey);

    event SetBackupKey(uint32 indexed userNo, address backupKey);

    event ReplacePrimeKey(uint32 indexed userNo, address newKey);

    // ##################
    // ##    Modifier  ##
    // ##################

    modifier onlyRegKey(address key) {
        require(_registeredKeys[key], "not registered key");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser() external {
        require(!_registeredKeys[msg.sender], "already registered");
        require(counterOfUsers + 1 > counterOfUsers, "counterOfUsers overflow");

        counterOfUsers++;

        _users[counterOfUsers].primeKey = msg.sender;

        _registeredKeys[msg.sender] = true;
        _userNo[msg.sender] = counterOfUsers;

        emit RegUser(counterOfUsers, msg.sender);
    }

    function setBackupKey(uint32 userNo, address backupKey) external {
        require(backupKey != address(0), "zero key");
        require(!_registeredKeys[backupKey], "used key");
        require(userNo <= counterOfUsers, "userNo overflow");

        User storage user = _users[userNo];

        require(msg.sender == user.primeKey, "wrong primeKey");

        user.backupKey = backupKey;
        _registeredKeys[backupKey] = true;

        emit SetBackupKey(userNo, backupKey);
    }

    function replacePrimeKey(uint32 userNo) external {
        require(userNo <= counterOfUsers, "userNo overflow");

        User storage user = _users[userNo];

        require(msg.sender == user.backupKey, "wrong backupKey");

        _userNo[user.primeKey] = 0;
        _userNo[user.backupKey] = userNo;

        user.primeKey = user.backupKey;
        user.backupKey = address(0);

        emit ReplacePrimeKey(userNo, user.primeKey);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isUser(address key) external returns (bool) {
        return checkID(userNo(key), key);
    }

    function checkID(uint32 userNo, address key)
        public
        onlyRegKey(key)
        returns (bool)
    {
        require(userNo > 0, "zero userNo");
        require(userNo <= counterOfUsers, "userNo overflow");

        return key == _users[userNo].primeKey;
    }

    function userNo(address key) public onlyRegKey(key) returns (uint32) {
        return _userNo[key];
    }
}
