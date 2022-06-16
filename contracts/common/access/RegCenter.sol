/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

contract RegCenter {
    struct User {
        address primeKey;
        address backupKey;
        bool flag;
    }

    // userNo => User
    mapping(uint40 => User) private _users;

    // key => bool
    mapping(address => bool) private _usedKeys;

    // primeKey => userNo
    mapping(address => uint40) private _userNo;

    uint40 public counterOfUsers;

    constructor() public {
        regUser();
    }

    // ##################
    // ##    Event     ##
    // ##################

    event RegUser(uint40 indexed userNo, address primeKey);

    event SetBackupKey(uint40 indexed userNo, address backupKey);

    event ReplacePrimeKey(uint40 indexed userNo, address newKey);

    event ResetBackupKeyFlag(uint40 indexed userNo);

    // ##################
    // ##    Modifier  ##
    // ##################

    modifier onlyRegKey(address key) {
        require(_usedKeys[key], "not registered key");
        _;
    }

    modifier onlyOwner() {
        require(_userNo[msg.sender] == 1, "not owner");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser() public {
        require(!_usedKeys[msg.sender], "already registered");
        require(counterOfUsers + 1 > counterOfUsers, "counterOfUsers overflow");

        counterOfUsers++;

        _users[counterOfUsers].primeKey = msg.sender;

        _usedKeys[msg.sender] = true;
        _userNo[msg.sender] = counterOfUsers;

        emit RegUser(counterOfUsers, msg.sender);
    }

    function setBackupKey(uint40 userNo, address backupKey) external {
        require(backupKey != address(0), "zero key");
        require(!_usedKeys[backupKey], "used key");

        User storage user = _users[userNo];

        require(msg.sender == user.primeKey, "wrong primeKey");
        require(!user.flag, "already set backup key");

        user.backupKey = backupKey;
        _usedKeys[backupKey] = true;

        user.flag = true;

        emit SetBackupKey(userNo, backupKey);
    }

    function replacePrimeKey(uint40 userNo) external {
        User storage user = _users[userNo];

        require(msg.sender == user.backupKey, "wrong backupKey");

        _userNo[user.primeKey] = 0;
        _userNo[user.backupKey] = userNo;

        user.primeKey = user.backupKey;
        user.backupKey = address(0);

        emit ReplacePrimeKey(userNo, user.primeKey);
    }

    function resetBackupKeyFlag(uint40 userNo) external onlyOwner {
        _users[userNo].flag = false;
        emit ResetBackupKeyFlag(userNo);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isUser(address key) external view returns (bool) {
        return checkID(userNo(key), key);
    }

    function checkID(uint40 userNo, address key)
        public
        view
        onlyRegKey(key)
        returns (bool)
    {
        require(userNo > 0, "zero userNo");
        require(userNo <= counterOfUsers, "userNo overflow");

        return key == _users[userNo].primeKey;
    }

    function userNo(address key) public view onlyRegKey(key) returns (uint40) {
        return _userNo[key];
    }
}
