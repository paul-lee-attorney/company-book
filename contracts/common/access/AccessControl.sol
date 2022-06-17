/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./Roles.sol";

contract AccessControl is Roles {
    bytes32 public constant KEEPERS = bytes32("Keepers");

    bytes32 public constant READERS = bytes32("Readers");

    uint40 private _directKeeper;

    uint40 private _owner;

    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        uint40 indexed owner,
        uint40 indexed directKeeper,
        address regCenter
    );

    event AbandonOwnership();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyOwner() {
        require(_msgSender() == _owner, "not owner");
        _;
    }

    modifier onlyDirectKeeper() {
        require(_msgSender() == _directKeeper, "not direct keeper");
        _;
    }

    modifier onlyKeeper() {
        require(hasRole(KEEPERS, _msgSender()), "not Keeper");
        _;
    }

    modifier ownerOrDirectKeeper() {
        require(
            _msgSender() == _owner || _msgSender() == _directKeeper,
            "not owner or directKeeper"
        );
        _;
    }

    modifier onlyReader() {
        require(hasRole(READERS, _msgSender()), "not READER");
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

    function init(
        uint40 owner,
        uint40 directKeeper,
        address regCenter
    ) public {
        _setRegCenter(regCenter);

        require(_owner == 0, "already set _owner ");
        require(_directKeeper == 0, "already set _directKeeper");

        _owner = owner;
        _directKeeper = directKeeper;

        _setRoleAdmin(KEEPERS, _directKeeper);
        _setRoleAdmin(READERS, _owner);

        emit Init(_owner, _directKeeper, _rc);
    }

    function abandonOwnership() public ownerOrDirectKeeper {
        _owner = 0;
        emit AbandonOwnership();
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() public view onlyUser returns (uint40) {
        return _owner;
    }

    function getDirectKeeper() public view onlyUser returns (uint40) {
        return _directKeeper;
    }
}
