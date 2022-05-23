/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./RegCenterSetting.sol";
import "./interfaces/IRoles.sol";

import "../lib/UserGroup.sol";

contract Roles is RegCenterSetting {
    using UserGroup for UserGroup.Group;

    struct RoleData {
        UserGroup.Group roleGroup;
        uint32 admin;
    }

    // NameOfRole => RoleData
    mapping(bytes32 => RoleData) private _roles;

    // ##################
    // ##   Event      ##
    // ##################

    event SetRoleAdmin(bytes32 indexed role, uint32 indexed admin);

    event RoleGranted(
        bytes32 indexed role,
        uint32 indexed member,
        uint32 indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        uint32 indexed member,
        uint32 indexed sender
    );

    // ##################
    // ##    写端口    ##
    // ##################

    function grantRole(bytes32 role, uint32 user)
        external
        theUser(roleAdmin(role))
    {
        if (_roles[role].roleGroup.addMember(user))
            emit RoleGranted(role, user, _msgSender());
    }

    function revokeRole(bytes32 role, uint32 user)
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
    function _setRoleAdmin(bytes32 role, uint32 acct) internal {
        require(acct > 0, "zero acct");
        require(roleAdmin(role) == 0, "already set role admin");

        _roles[role].admin = acct;
        emit SetRoleAdmin(role, acct);
    }

    function _removeRole(bytes32 role, uint32 acct) private {
        if (_roles[role].roleGroup.removeMember(acct))
            emit RoleRevoked(role, acct, _msgSender());
    }

    function _copyRoleTo(address target, bytes32 role) internal {
        uint32[] memory users = members(role);
        uint256 len = users.length;
        for (uint256 i = 0; i < len; i++)
            IRoles(target).grantRole(role, users[i]);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function hasRole(bytes32 role, uint32 acct) public view returns (bool) {
        return _roles[role].roleGroup.isMember(acct);
    }

    function members(bytes32 role) public view returns (uint32[]) {
        return _roles[role].roleGroup.getMembers();
    }

    function roleAdmin(bytes32 role) public view returns (uint32) {
        return _roles[role].admin;
    }
}
