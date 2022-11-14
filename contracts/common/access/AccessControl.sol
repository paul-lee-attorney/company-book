// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAccessControl.sol";
import "./RegCenterSetting.sol";
import "../lib/RolesRepo.sol";

contract AccessControl is IAccessControl, RegCenterSetting {
    using RolesRepo for RolesRepo.Roles;

    enum TitleOfManagers {
        Owner,
        GeneralCounsel
    }

    bytes32 constant ATTORNEYS = bytes32("Attorneys");

    RolesRepo.Roles private _roles;

    // ##################
    // ##   修饰器      ##
    // ##################

    modifier onlyManager(uint8 title) {
        require(
            _roles.isManager(title, _msgSender()),
            "AC.onlyManager: not the specific manager"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            _gk.isKeeper(msg.sender),
            "AC.onlyKeeper: not Keeper"
        );
        _;
    }

    modifier onlyAttorney() {
        require(
            _roles.hasRole(ATTORNEYS, _msgSender()),
            "AC.onlyAttorney: not Attorney"
        );
        _;
    }

    modifier attorneyOrKeeper() {
        require(
            _roles.hasRole(ATTORNEYS, _msgSender()) ||
                _gk.isKeeper(msg.sender),
            "not Attorney or Bookeeper"
        );
        _;
    }

    modifier onlyPending() {
        require(_roles.state < 2, "AC.onlyPending: Doc is finalized");
        _;
    }

    modifier onlyFinalized() {
        require(_roles.state == 2, "AC.onlyFinalized: Doc is still pending");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        uint40 owner,
        address regCenter,
        address generalKeeper
    ) public {

        _setRegCenter(regCenter);

        _setGeneralKeeper(generalKeeper);

        _roles.setManager(uint8(TitleOfManagers.Owner), 0, owner);
        // _roles.setManager(uint8(TitleOfManagers.DirectKeeper), directKeeper);

        emit Init(owner, address(_rc), generalKeeper);
    }

    function setManager(
        uint8 title,
        uint40 acct
    ) external {
        _roles.setManager(title, _msgSender(), acct);
    }

    function grantRole(bytes32 role, uint40 acct) external {
        _roles.grantRole(role, _msgSender(), acct);
    }

    function revokeRole(bytes32 role, uint40 acct) external {
        _roles.revokeRole(role, _msgSender(), acct);
    }

    function renounceRole(bytes32 role) external {
        _roles.renounceRole(role, _msgSender());
    }

    function abandonRole(bytes32 role) external {
        _roles.abandonRole(role, _msgSender());
    }

    function setRoleAdmin(bytes32 role, uint40 acct) external onlyManager(0) {
        _roles.setRoleAdmin(role, _msgSender(), acct);
    }

    function lockContents() public onlyPending {
        _roles.abandonRole(ATTORNEYS, _msgSender());
        _roles.state = 2;

        emit LockContents();
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getManager(uint8 title) public view returns (uint40) {
        return _roles.getManager(title);
    }

    function getManagerKey(uint8 title) public view returns (address) {
        return _rc.primeKey(getManager(title));
    }

    function finalized() public view returns (bool) {
        return _roles.state == 2;
    }

    function hasRole(address acctAddr, bytes32 role)
        external
        view
        returns (bool)
    {
        return _roles.hasRole(role, _rc.userNo(acctAddr));
    }
}
