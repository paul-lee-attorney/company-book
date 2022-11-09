// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

import "../lib/RolesRepo.sol";

contract RegCenter is IRegCenter {
    using RolesRepo for RolesRepo.Roles;

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

    // ==== Role ====

    // docUserNo =>Roles
    mapping(uint256 => RolesRepo.Roles) private _roles;

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

    // ==== Roles ====

    function setManager(uint8 title, address addrOfAcct) external onlyContract {
        require(addrOfAcct != address(0), "RC.setManager: zero acct's address");

        uint40 doc = _userNo[msg.sender];
        uint40 acct = _userNo[addrOfAcct];

        _roles[doc].setManager(title, acct);

        emit SetManager(doc, title, acct);
    }

    function grantRole(
        bytes32 role,
        address addrOfOriginator,
        uint40 acct
    ) external onlyContract {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );
        _roles[doc].grantRole(role, originator, acct);

        emit GrantRole(doc, role, acct);
    }

    function _getRegUserNo(address caller, address addrOfOriginator)
        private
        view
        returns (uint40 doc, uint40 originator)
    {
        require(caller != address(0), "RC.getRegUserNo: zero address caller");
        require(
            addrOfOriginator != address(0),
            "RC.getRegUserNo: zero address originator"
        );

        doc = _userNo[caller];
        require(doc > 0, "contract not registered");

        originator = _userNo[addrOfOriginator];
        require(originator > 0, "RC.getRegUerNo: originator not registered");
    }

    function revokeRole(
        bytes32 role,
        address addrOfOriginator,
        uint40 acct
    ) external onlyContract {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );
        _roles[doc].revokeRole(role, originator, acct);

        emit RevokeRole(doc, role, acct);
    }

    function renounceRole(bytes32 role, address addrOfOriginator)
        external
        onlyContract
    {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );
        _roles[doc].renounceRole(role, originator);

        emit RenounceRole(doc, role, originator);
    }

    function abandonRole(bytes32 role, address addrOfOriginator)
        external
        onlyContract
    {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );
        _roles[doc].abandonRole(role, originator);

        emit AbandonRole(doc, role);
    }

    function setRoleAdmin(
        bytes32 role,
        address addrOfOriginator,
        uint40 acct
    ) external onlyContract {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );
        _roles[doc].setRoleAdmin(role, originator, acct);

        emit SetRoleAdmin(doc, role, acct);
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

    // ==== Role ====
    function hasRole(bytes32 role, address addrOfOriginator)
        external
        view
        onlyContract
        returns (bool)
    {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );

        return _roles[doc].hasRole(role, originator);
    }

    function isManager(uint8 title, address addrOfOriginator)
        external
        view
        onlyContract
        returns (bool)
    {
        (uint40 doc, uint40 originator) = _getRegUserNo(
            msg.sender,
            addrOfOriginator
        );

        return _roles[doc].isManager(title, originator);
    }

    function getManager(uint8 title) public view onlyContract returns (uint40) {
        uint40 doc = _userNo[msg.sender];

        return getManagerOf(title, doc);
    }

    function getManagerKey(uint8 title)
        external
        view
        onlyContract
        returns (address)
    {
        uint40 manager = getManager(title);
        return _users[manager].primeKey;
    }

    function getManagerOf(uint8 title, uint40 doc)
        public
        view
        returns (uint40)
    {
        require(doc > 0, "contract is not registered");

        return _roles[doc].managers[title];
    }
}
