/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./RegCenterSetting.sol";
import "./IRoles.sol";

import "../lib/EnumerableSet.sol";

import "./IRoles.sol";

contract Roles is IRoles, RegCenterSetting {
    using EnumerableSet for EnumerableSet.UintSet;

    struct RoleData {
        EnumerableSet.UintSet roleGroup;
        uint40 admin;
    }

    // NameOfRole => RoleData
    mapping(bytes32 => RoleData) private _roles;

    // ##################
    // ##   Event      ##
    // ##################

    event SetRoleAdmin(bytes32 indexed role, uint40 indexed admin);

    event RoleGranted(
        bytes32 indexed role,
        uint40 indexed member,
        uint40 indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        uint40 indexed member,
        uint40 indexed sender
    );

    // ##################
    // ##    写端口    ##
    // ##################

    function grantRole(bytes32 role, uint40 user)
        external
        theUser(roleAdmin(role))
    {
        if (_roles[role].roleGroup.add(uint256(user)))
            emit RoleGranted(role, user, _msgSender());
    }

    function revokeRole(bytes32 role, uint40 user)
        external
        theUser(roleAdmin(role))
    {
        _removeRole(role, user);
    }

    function renounceRole(bytes32 role) external {
        _removeRole(role, _msgSender());
    }

    function abandonRole(bytes32 role) public theUser(roleAdmin(role)) {
        delete _roles[role];
    }

    // very important API for role admin setting, which shall be only exposed to AccessControl func.
    function _setRoleAdmin(bytes32 role, uint40 acct) internal {
        require(acct > 0, "zero acct");
        require(roleAdmin(role) == 0, "already set role admin");

        _roles[role].admin = acct;
        emit SetRoleAdmin(role, acct);
    }

    function _removeRole(bytes32 role, uint40 acct) private {
        if (_roles[role].roleGroup.remove(uint256(acct)))
            emit RoleRevoked(role, acct, _msgSender());
    }

    function _copyRoleTo(address target, bytes32 role) internal {
        uint40[] memory users = roleMembers(role);
        uint256 len = users.length;
        for (uint256 i = 0; i < len; i++)
            IRoles(target).grantRole(role, users[i]);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function hasRole(bytes32 role, uint40 acct)
        public
        view
        onlyUser
        returns (bool)
    {
        return _roles[role].roleGroup.contains(uint256(acct));
    }

    function roleMembers(bytes32 role) public view onlyUser returns (uint40[]) {
        return _roles[role].roleGroup.valuesToUint40();
    }

    function roleAdmin(bytes32 role) public view onlyUser returns (uint40) {
        return _roles[role].admin;
    }
}
