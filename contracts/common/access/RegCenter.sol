// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "./EntitiesMapping.sol";
import "./IRegCenter.sol";

import "../lib/EnumsRepo.sol";
import "../lib/EnumerableSet.sol";
import "../lib/RolesRepo.sol";

contract RegCenter is IRegCenter {
    using EnumerableSet for EnumerableSet.UintSet;
    using RolesRepo for RolesRepo.Roles;

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

    // ==== Role ====

    // docUserNo =>Roles
    mapping(uint40 => RolesRepo.Roles) private _roles;

    constructor(uint32 blocks_per_hour) {
        regUser(uint8(EnumsRepo.RoleOfUser.EOA), 0);
        _BLOCKS_PER_HOUR = blocks_per_hour;
    }

    // ==== Entity ====

    struct Entity {
        mapping(uint40 => bool) isKeeper;
        // RoleOfUser => user
        mapping(uint8 => uint40) members;
    }

    // userNo => entityNo
    mapping(uint40 => uint40) private _entityNo;

    // entityNo => Entity
    mapping(uint40 => Entity) private _entities;

    EnumerableSet.UintSet private _entitiesList;

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

    modifier onlyContract() {
        require(_isContract(msg.sender), "not a contract");
        _;
    }

    modifier entityExist(uint40 entity) {
        require(isEntity(entity), "EM.entityExist: entity not exist");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function regUser(uint8 roleOfUser, uint40 entity) public returns (uint40) {
        require(!_usedKeys[msg.sender], "RC.regUser: already registered");

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
        } else if (roleOfUser > uint8(EnumsRepo.RoleOfUser.BookOfShares)) {
            require(_isContract(msg.sender), "only CA may join Entity");

            _joinEntity(entity, _counterOfUsers, roleOfUser);
        }

        return _counterOfUsers;
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

    function setBackupKey(uint40 user, address backupKey) external override {
        require(backupKey != address(0), "zero key");
        require(!_usedKeys[backupKey], "used key");

        User storage u = _users[user];

        require(msg.sender == u.primeKey, "wrong primeKey");
        require(!_isContract(msg.sender), "msgSender shall not be a contract");

        require(!u.flag, "already set backup key");

        u.backupKey = backupKey;
        _usedKeys[backupKey] = true;

        u.flag = true;

        emit SetBackupKey(user, backupKey);
    }

    function replacePrimeKey(uint40 user) external {
        User storage u = _users[user];

        require(msg.sender == u.backupKey, "wrong backupKey");

        delete _userNo[u.primeKey];
        _userNo[u.backupKey] = user;

        u.primeKey = u.backupKey;
        u.backupKey = address(0);

        emit ReplacePrimeKey(user, u.primeKey);
    }

    function resetBackupKeyFlag(uint40 user) external onlyOwner {
        _users[user].flag = false;
        emit ResetBackupKeyFlag(user);
    }

    // ======== Entity ========

    function _createEntity(
        uint40 user,
        uint8 typeOfEntity,
        uint8 roleOfUser
    ) private {
        require(
            roleOfUser == uint8(EnumsRepo.RoleOfUser.EOA) ||
                roleOfUser == uint8(EnumsRepo.RoleOfUser.BookOfShares),
            "only EOA and BOS may create a new Entity"
        );

        if (_entitiesList.add(user)) {
            _entityNo[user] = user;
            _entities[user].members[roleOfUser] = user;
            emit CreateEntity(user, typeOfEntity, roleOfUser);
        }
    }

    function _joinEntity(
        uint40 entity,
        uint40 user,
        uint8 roleOfUser
    ) private entityExist(entity) {
        require(_entityNo[user] == 0, "pls quit from other Entity first");

        Entity storage corp = _entities[entity];

        if (roleOfUser < uint8(EnumsRepo.RoleOfUser.InvestmentAgreement)) {
            require(
                corp.members[roleOfUser] == 0,
                "role already be registered"
            );
        }

        _entityNo[user] = entity;
        corp.members[roleOfUser] = user;

        if (
            roleOfUser > uint8(EnumsRepo.RoleOfUser.GeneralKeeper) &&
            roleOfUser < uint8(EnumsRepo.RoleOfUser.BOSCalculator)
        ) {
            corp.isKeeper[user] = true;
        }

        emit JoinEntity(entity, user, roleOfUser);
    }

    function _quitEntity(uint40 user, uint8 roleOfUser) internal {
        require(
            roleOfUser > uint8(EnumsRepo.RoleOfUser.BookOfShares),
            "roleOfUser overflow"
        );
        require(
            roleOfUser < uint8(EnumsRepo.RoleOfUser.EndPoint),
            "roleOfUser overflow"
        );

        uint40 entity = _entityNo[user];

        Entity storage corp = _entities[entity];

        require(corp.members[roleOfUser] == user, "wrong roleOfUser");

        if (corp.isKeeper[user]) corp.isKeeper[user] = false;

        delete corp.members[roleOfUser];
        delete _entityNo[user];

        emit QuitEntity(entity, user, roleOfUser);
    }

    // ==== EquityInvestment ====

    // function investIn(
    //     uint40 usrInvestor,
    //     uint64 parValue,
    //     bool checkRingStruct
    // ) external returns (bool) {
    //     if (!isEntity(usrInvestor)) {
    //         require(!_isContract(_users[usrInvestor].primeKey), "not an EOA");

    //         _createEntity(
    //             usrInvestor,
    //             uint8(EnumsRepo.TypeOfEntity.EOA),
    //             uint8(EnumsRepo.RoleOfUser.EOA)
    //         );
    //     }

    //     return
    //         _investIn(
    //             usrInvestor,
    //             _userNo[msg.sender],
    //             parValue,
    //             checkRingStruct
    //         );
    // }

    // function exitOut(uint40 usrInvestor) external returns (bool) {
    //     return _exitOut(usrInvestor, _userNo[msg.sender]);
    // }

    // function updateParValue(uint40 usrInvestor, uint64 parValue)
    //     external
    //     returns (bool)
    // {
    //     return _updateParValue(usrInvestor, _userNo[msg.sender], parValue);
    // }

    // ==== Director ====

    // function takePosition(uint40 usrCandy, uint8 title)
    //     external
    //     returns (bool)
    // {
    //     require(isUser(usrCandy), "investor is not a regUser");

    //     if (!isEntity(usrCandy)) {
    //         require(!_isContract(_users[usrCandy].primeKey), "not an EOA");

    //         _createEntity(
    //             usrCandy,
    //             uint8(EnumsRepo.TypeOfEntity.EOA),
    //             uint8(EnumsRepo.RoleOfUser.EOA)
    //         );
    //     }

    //     return _takePosition(usrCandy, _userNo[msg.sender], title);
    // }

    // function quitPosition(uint40 usrDirector) external returns (bool) {
    //     return _quitPosition(usrDirector, _userNo[msg.sender]);
    // }

    // function changeTitle(uint40 usrDirector, uint8 title)
    //     external
    //     returns (bool)
    // {
    //     return _changeTitle(usrDirector, _userNo[msg.sender], title);
    // }

    // ==== Roles ====

    function setManager(uint8 title, address addrOfAcct) external onlyContract {
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
        doc = _userNo[caller];
        require(doc > 0, "contract not registered");

        originator = _userNo[addrOfOriginator];
        require(originator > 0, "originator not registered");
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
        return _counterOfUsers;
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

    function isUser(address key) public view returns (bool) {
        return _userNo[key] > 0;
    }

    function checkID(uint40 user, address key)
        public
        view
        onlyRegKey(key)
        returns (bool)
    {
        require(user > 0, "RC.checkID: zero user");
        require(user <= _counterOfUsers, "RC.checkID: user overflow");

        return key == _users[user].primeKey;
    }

    function userNo(address key) public view onlyRegKey(key) returns (uint40) {
        return _userNo[key];
    }

    // ==== Entity ====
    function isEntity(uint40 entity) public view returns (bool) {
        return (_entities[entity].members[uint8(EnumsRepo.RoleOfUser.EOA)] >
            0 ||
            _entities[entity].members[
                uint8(EnumsRepo.RoleOfUser.BookOfShares)
            ] >
            0);
    }

    function entityNo(address acct) public view returns (uint40) {
        uint40 user = _userNo[acct];
        require(user > 0, "RC.entityNo: userNo not exist");

        uint40 entity = _entityNo[user];
        require(entity > 0, "RC.entityNo: entityNo not exist");

        return entity;
    }

    // function entityNo(address caller) external view returns (uint40) {
    //     return _entityNo[_userNo[caller]];
    // }

    function memberOfEntity(uint40 entity, uint8 role)
        external
        view
        returns (uint40)
    {
        return _entities[entity].members[role];
    }

    function isKeeper(address caller) external view returns (bool) {
        uint40 entity = entityNo(msg.sender);
        uint40 user = _userNo[caller];

        return _entities[entity].isKeeper[user];
    }

    // ==== Element ====

    // function getEntity(uint40 entity)
    //     external
    //     view
    //     returns (
    //         uint8,
    //         uint40,
    //         uint88,
    //         uint16,
    //         uint88,
    //         uint16
    //     )
    // {
    //     return _getEntity(entity);
    // }

    // function getConnection(uint88 con)
    //     external
    //     view
    //     returns (
    //         uint88,
    //         uint88,
    //         uint64
    //     )
    // {
    //     return _getConnection(con);
    // }

    // function isRoot(uint40 entity) external view returns (bool) {
    //     return _isRoot(entity);
    // }

    // function isLeaf(uint40 entity) external view returns (bool) {
    //     return _isLeaf(entity);
    // }

    // ==== Graph ====

    // function getUpBranches(uint40 origin)
    //     external
    //     view
    //     returns (uint40[] entities, uint88[] connections)
    // {
    //     return _getUpBranches(origin);
    // }

    // function getDownBranches(uint40 origin)
    //     external
    //     view
    //     returns (uint40[] entities, uint88[] connections)
    // {
    //     return _getDownBranches(origin);
    // }

    // function getRoundGraph(uint40 origin)
    //     external
    //     view
    //     returns (uint40[] entities, uint88[] connections)
    // {
    //     return _getRoundGraph(origin);
    // }

    // ==== Role ====
    function hasRole(bytes32 role, address addrOfOriginator)
        external
        override
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
        override
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

    function getManager(uint8 title) public override view onlyContract returns (uint40) {
        uint40 doc = _userNo[msg.sender];

        return getManagerOf(title, doc);
    }

    function getManagerKey(uint8 title)
        external
        override
        view
        onlyContract
        returns (address)
    {
        uint40 manager = getManager(title);
        return _users[manager].primeKey;
    }

    function getManagerOf(uint8 title, uint40 doc)
        public
        override
        view
        returns (uint40)
    {
        require(title < 3, "title overflow");
        require(doc > 0, "contract is not registered");

        return _roles[doc].managers[title];
    }
}
