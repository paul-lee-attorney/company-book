/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./Roles.sol";

contract AccessControl is Roles {
    bytes32 public constant KEEPERS = bytes32("Keepers");

    bytes32 public constant READERS = bytes32("Readers");

    uint32 private _directKeeper;

    uint32 private _owner;

    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        uint32 indexed owner,
        uint32 indexed directKeeper,
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
        uint32 owner,
        uint32 directKeeper,
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

    function getOwner() public view returns (uint32) {
        return _owner;
    }

    function getDirectKeeper() public view returns (uint32) {
        return _directKeeper;
    }
}
