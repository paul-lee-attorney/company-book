/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IRegCenter.sol";
import "../lib/EnumsRepo.sol";
import "./EntitiesMapping.sol";

contract RegCenter is IRegCenter, EntitiesMapping {
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

    uint40 private _counterOfUsers;

    uint32 private _BLOCKS_PER_HOUR;

    constructor(uint32 blocks_per_hour) public {
        regUser(uint8(EnumsRepo.RoleOfUser.EOA), 0);
        _BLOCKS_PER_HOUR = blocks_per_hour;
    }

    // ##################
    // ##    Modifier  ##
    // ##################

    modifier onlyRegKey(address key) {
        require(_usedKeys[key], "not registered key");
        _;
    }

    modifier onlyOwner() {
        require(_userNo[msg.sender] == 1, "not the owner of RegCenter");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser(uint8 roleOfUser, uint40 entity) public {
        require(!_usedKeys[msg.sender], "already registered");

        _counterOfUsers++;

        _users[_counterOfUsers].primeKey = msg.sender;

        _usedKeys[msg.sender] = true;
        _userNo[msg.sender] = _counterOfUsers;

        emit RegUser(_counterOfUsers, msg.sender);

        if (roleOfUser == uint8(EnumsRepo.RoleOfUser.BookOfShares)) {
            require(_isContract(msg.sender), "BOS shall be a CA");

            _createEntity(
                _counterOfUsers,
                uint8(EnumsRepo.TypeOfEntity.Company),
                roleOfUser
            );
        } else if (
            roleOfUser > uint8(EnumsRepo.RoleOfUser.BookOfShares) &&
            roleOfUser < uint8(EnumsRepo.RoleOfUser.EndPoint)
        ) {
            require(_isContract(msg.sender), "only CA may join Entity");

            _joinEntity(entity, _counterOfUsers, roleOfUser);
        }
    }

    function quitEntity(uint8 roleOfUser) external {
        _quitEntity(_userNo[msg.sender], roleOfUser);
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size > 0;
    }

    function setBackupKey(uint40 userNo, address backupKey) external {
        require(backupKey != address(0), "zero key");
        require(!_usedKeys[backupKey], "used key");

        User storage user = _users[userNo];

        require(msg.sender == user.primeKey, "wrong primeKey");
        require(!_isContract(msg.sender), "msgSender shall not be a contract");

        require(!user.flag, "already set backup key");

        user.backupKey = backupKey;
        _usedKeys[backupKey] = true;

        user.flag = true;

        emit SetBackupKey(userNo, backupKey);
    }

    function replacePrimeKey(uint40 userNo) external {
        User storage user = _users[userNo];

        require(msg.sender == user.backupKey, "wrong backupKey");

        delete _userNo[user.primeKey];
        _userNo[user.backupKey] = userNo;

        user.primeKey = user.backupKey;
        user.backupKey = address(0);

        emit ReplacePrimeKey(userNo, user.primeKey);
    }

    function resetBackupKeyFlag(uint40 userNo) external onlyOwner {
        _users[userNo].flag = false;
        emit ResetBackupKeyFlag(userNo);
    }

    // ==== EquityInvestment ====

    function investIn(
        uint40 usrInvestor,
        uint64 parValue,
        bool checkRingStruct
    ) external returns (bool) {
        if (!isEntity(usrInvestor)) {
            require(!_isContract(_users[usrInvestor].primeKey), "not an EOA");

            _createEntity(
                usrInvestor,
                uint8(EnumsRepo.TypeOfEntity.EOA),
                uint8(EnumsRepo.RoleOfUser.EOA)
            );
        }

        return
            _investIn(
                usrInvestor,
                _userNo[msg.sender],
                parValue,
                checkRingStruct
            );
    }

    function exitOut(uint40 usrInvestor) external returns (bool) {
        return _exitOut(usrInvestor, _userNo[msg.sender]);
    }

    function updateParValue(uint40 usrInvestor, uint64 parValue)
        external
        returns (bool)
    {
        return _updateParValue(usrInvestor, _userNo[msg.sender], parValue);
    }

    // ==== Director ====

    function takePosition(uint40 usrCandy, uint8 title)
        external
        returns (bool)
    {
        require(isUser(usrCandy), "investor is not a regUser");

        if (!isEntity(usrCandy)) {
            require(!_isContract(_users[usrCandy].primeKey), "not an EOA");

            _createEntity(
                usrCandy,
                uint8(EnumsRepo.TypeOfEntity.EOA),
                uint8(EnumsRepo.RoleOfUser.EOA)
            );
        }

        return _takePosition(usrCandy, _userNo[msg.sender], title);
    }

    function quitPosition(uint40 usrDirector) external returns (bool) {
        return _quitPosition(usrDirector, _userNo[msg.sender]);
    }

    function changeTitle(uint40 usrDirector, uint8 title)
        external
        returns (bool)
    {
        return _changeTitle(usrDirector, _userNo[msg.sender], title);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function counterOfUsers() external view returns (uint40) {
        return _counterOfUsers;
    }

    function blocksPerHour() external view returns (uint32) {
        return _BLOCKS_PER_HOUR;
    }

    function primeKey(uint40 userNo) external view returns (address) {
        return _users[userNo].primeKey;
    }

    function isContract(uint40 userNo) external view returns (bool) {
        return _isContract(_users[userNo].primeKey);
    }

    function isUser(address key) public view returns (bool) {
        return _userNo[key] > 0;
    }

    function checkID(uint40 userNo, address key)
        public
        view
        onlyRegKey(key)
        returns (bool)
    {
        require(userNo > 0, "zero userNo");
        require(userNo <= _counterOfUsers, "userNo overflow");

        return key == _users[userNo].primeKey;
    }

    function userNo(address key) public view onlyRegKey(key) returns (uint40) {
        return _userNo[key];
    }

    // ==== Entity ====

    function entityNo(uint40 user) external view returns (uint40) {
        return _entityNo[user];
    }

    function memberOfEntity(uint40 entity, uint8 role)
        external
        view
        returns (uint40)
    {
        return _memberOfEntity(entity, role);
    }

    // ==== Element ====

    function getEntity(uint40 entity)
        external
        view
        returns (
            uint8,
            uint40,
            uint88,
            uint16,
            uint88,
            uint16
        )
    {
        return _getEntity(entity);
    }

    function getConnection(uint88 con)
        external
        view
        returns (
            uint88,
            uint88,
            uint64
        )
    {
        return _getConnection(con);
    }

    function isRoot(uint40 entity) external view returns (bool) {
        return _isRoot(entity);
    }

    function isLeaf(uint40 entity) external view returns (bool) {
        return _isLeaf(entity);
    }

    // ==== Graph ====

    function getUpBranches(uint40 origin)
        external
        returns (uint40[] entities, uint88[] connections)
    {
        return _getUpBranches(origin);
    }

    function getDownBranches(uint40 origin)
        external
        returns (uint40[] entities, uint88[] connections)
    {
        return _getDownBranches(origin);
    }

    function getRoundGraph(uint40 origin)
        external
        returns (uint40[] entities, uint88[] connections)
    {
        return _getRoundGraph(origin);
    }
}
