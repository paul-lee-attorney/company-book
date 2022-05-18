/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

contract KeyPerson {
    struct Person {
        address primaryKey;
        address backupKey;
    }

    // title => person
    mapping(bytes32 => Person) private _people;

    // ##################
    // ##    Event     ##
    // ##################

    event SetPrimaryKey(bytes32 title, address primaryKey);

    event SetBackupKey(bytes32 title, address backupKey);

    event ReplacePrimaryKey(bytes32 title, address oldKey, address newKey);

    event HandoverPosition(bytes32 title, address oldKey, address newKey);

    event QuitPosition(bytes32 title);

    // ##################
    // ##    修饰器    ##
    // ##################

    modifier onlyPerson(bytes32 title) {
        require(msg.sender == _people[title].primaryKey, "not right person");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function _setPrimaryKey(bytes32 title, address primaryKey) internal {
        require(
            _people[title].primaryKey == address(0),
            "already set primary key"
        );
        _people[title].primaryKey = primaryKey;

        emit SetPrimaryKey(title, primaryKey);
    }

    function setBackupKey(bytes32 title, address backupKey)
        external
        onlyPerson(title)
    {
        _people[title].backupKey = backupKey;

        emit SetBackupKey(title, backupKey);
    }

    function replacePrimaryKey(bytes32 title) external {
        require(msg.sender == _people[title].backupKey, "not backupKey");

        address oldKey = _people[title].primaryKey;

        _people[title].primaryKey = _people[title].backupKey;

        emit ReplacePrimaryKey(title, oldKey, _people[title].primaryKey);
    }

    function handoverPosition(bytes32 title, address newKey)
        public
        onlyPerson(title)
    {
        address oldKey = _people[title].primaryKey;

        _people[title].backupKey = address(0);
        _people[title].primaryKey = newKey;

        emit HandoverPosition(title, oldKey, newKey);
    }

    function quitPosition(bytes32 title) public onlyPerson(title) {
        _people[title].primaryKey = address(0);
        _people[title].backupKey = address(0);

        emit QuitPosition(title);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function primaryKey(bytes32 title) public view returns (address) {
        return _people[title].primaryKey;
    }

    function backupKey(bytes32 title) public view returns (address) {
        return _people[title].backupKey;
    }
}
