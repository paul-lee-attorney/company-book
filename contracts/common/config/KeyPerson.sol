/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// import "../utils/Context.sol";

contract KeyPerson {
    struct Person {
        address primaryKey;
        address backupKey;
    }

    // title => person
    mapping(bytes32 => Person) private _people;

    // ##################
    // ##    修饰器    ##
    // ##################

    modifier onlyPerson(bytes32 title) {
        require(msg.sender == _people[title].primaryKey, "not right person");
        _;
    }

    // modifier fromPerson(bytes32 title) {
    //     require(
    //         _msgSender == _people[title].primaryKey,
    //         "not from right person"
    //     );
    //     _;
    // }

    // ##################
    // ##    写端口    ##
    // ##################

    function _setPrimaryKey(bytes32 title, address primaryKey) internal {
        require(
            _people[title].primaryKey == address(0),
            "already set primary key"
        );
        _people[title].primaryKey = primaryKey;
    }

    function setBackupKey(bytes32 title, address backup) external {
        require(msg.sender == _people[title].primaryKey, "wrong primaryKey");

        _people[title].backupKey = backup;
    }

    function replacePrimaryKey(bytes32 title) external {
        require(msg.sender == _people[title].backupKey, "not backupKey");

        _people[title].primaryKey = _people[title].backupKey;
    }

    function handoverPosition(bytes32 title, address keeper)
        public
        onlyPerson(title)
    {
        _people[title].backupKey = address(0);
        _people[title].primaryKey = keeper;
    }

    function quitPosition(bytes32 title) public onlyPerson(title) {
        _people[title].primaryKey = address(0);
        _people[title].backupKey = address(0);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function _primaryKey(bytes32 title) internal view returns (address) {
        return _people[title].primaryKey;
    }

    function _backupKey(bytes32 title) internal view returns (address) {
        return _people[title].backupKey;
    }
}
