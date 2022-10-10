// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAccessControl.sol";
import "./RegCenterSetting.sol";

contract AccessControl is IAccessControl, RegCenterSetting {
    bool internal _finalized;
    bool private _initiated;

    // bytes32 constant KEEPERS = keccak256("Keepers");
    bytes32 constant ATTORNEYS = keccak256("Attorneys");

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyManager(uint8 title) {
        require(
            _rc.isManager(title, msg.sender),
            "AC.Md.onlyManager: not the specific manager"
        );
        _;
    }

    modifier onlyOwnerOrBookeeper() {
        require(
            _rc.isManager(0, msg.sender) || _rc.isManager(1, msg.sender),
            "neither owner nor bookeeper"
        );
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(
            _rc.hasRole(role, msg.sender),
            "AC.onlyRole: caller not has Role"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            _rc.isKeeper(msg.sender) || _rc.isManager(1, msg.sender),
            "AC.onlyKeeper: not Keeper"
        );
        _;
    }

    modifier onlyAttorney() {
        require(
            _rc.hasRole(ATTORNEYS, msg.sender),
            "AC.onlyAttorney: not Attorney"
        );
        _;
    }

    modifier attorneyOrKeeper() {
        require(
            _rc.hasRole(ATTORNEYS, msg.sender) ||
                _rc.isKeeper(msg.sender) ||
                _rc.isManager(1, msg.sender),
            "not Attorney or Bookeeper"
        );
        _;
    }

    // ==== DocState ====

    modifier onlyPending() {
        require(!_finalized, "Doc is _finalized");
        _;
    }

    modifier onlyFinalized() {
        require(_finalized, "Doc is still pending");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        uint8 roleOfUser,
        uint40 entity
    ) public {
        require(!_initiated, "already initiated.");

        _initiated = true;

        _setRegCenter(regCenter);

        _rc.regUser(roleOfUser, entity);

        _rc.setManager(0, owner);
        _rc.setManager(1, directKeeper);

        emit Init(owner, directKeeper, address(_rc));
    }

    // function regThisContract(uint8 roleOfUser, uint40 entity) public {
    //     uint40 userNo = _rc.regUser(roleOfUser, entity);
    //     emit RegThisContract(userNo);
    // }

    function setManager(
        uint8 title,
        address caller,
        address acct
    ) external onlyOwnerOrBookeeper {
        require(
            title > 1 || _rc.isManager(title, caller),
            "AC.setManager: caller does not has title"
        );
        _rc.setManager(title, acct);
    }

    function grantRole(bytes32 role, uint40 acct) external {
        _rc.grantRole(role, msg.sender, acct);
    }

    function revokeRole(bytes32 role, uint40 acct) external {
        _rc.revokeRole(role, msg.sender, acct);
    }

    function renounceRole(bytes32 role) external {
        _rc.renounceRole(role, msg.sender);
    }

    function abandonRole(bytes32 role) external {
        _rc.abandonRole(role, msg.sender);
    }

    function setRoleAdmin(bytes32 role, uint40 acct) external onlyManager(0) {
        _rc.setRoleAdmin(role, msg.sender, acct);
    }

    function lockContents() public onlyPending {
        _rc.abandonRole(ATTORNEYS, msg.sender);
        _rc.setManager(2, address(0));
        _finalized = true;

        emit LockContents();
    }

    function quitEntity(uint8 roleOfUser) external onlyManager(0) {
        _rc.quitEntity(roleOfUser);
    }

    // function copyRoleTo(bytes32 role, address to) public onlyManager(1) {
    //     _rc.copyRoleTo(role, msg.sender, to);
    // }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getManager(uint8 title) public view returns (uint40) {
        return _rc.getManager(title);
    }

    function getManagerKey(uint8 title) public view returns (address) {
        return _rc.getManagerKey(title);
    }

    function finalized() external view returns (bool) {
        return _finalized;
    }

    function hasRole(address acctAddr, bytes32 role)
        external
        view
        returns (bool)
    {
        return _rc.hasRole(role, acctAddr);
    }
}
