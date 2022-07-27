/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./Roles.sol";
import "./IAccessControl.sol";

// import "./RegCenterSetting.sol";

// import "../lib/RolesRepo.sol";

contract AccessControl is IAccessControl, Roles {
    bytes32 public constant KEEPERS = bytes32("Keepers");

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

    event QuitEntity(uint8 roleOfUser);

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

        emit Init(_owner, _directKeeper, _rc);
    }

    function abandonOwnership() external ownerOrDirectKeeper {
        _owner = 0;
        emit AbandonOwnership();
    }

    function quitEntity(uint8 roleOfUser) external ownerOrDirectKeeper {
        _rc.quitEntity(roleOfUser);
        emit QuitEntity(roleOfUser);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() public view returns (uint40) {
        return _owner;
    }

    function getDirectKeeper() public view returns (uint40) {
        return _directKeeper;
    }
}
