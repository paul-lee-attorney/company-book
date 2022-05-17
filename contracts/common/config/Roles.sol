/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./KeyPerson.sol";

import "../lib/ArrayUtils.sol";

contract Roles is KeyPerson {
    using ArrayUtils for address[];

    struct RoleData {
        mapping(address => bool) isMember;
        address[] members;
        bytes32 admin;
    }

    // NameOfRole => RoleData
    mapping(bytes32 => RoleData) private _roles;

    // ##################
    // ##   Event      ##
    // ##################

    event SetRoleAdmin(bytes32 indexed role, bytes32 indexed adminTitle);

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    // ##################
    // ##   修饰器     ##
    // ##################

    // modifier onlyRole(bytes32 role) {
    //     require(
    //         hasRole(role, msg.sender),
    //         "account does not have sepecific ROLE"
    //     );
    //     _;
    // }

    // ##################
    // ##    写端口    ##
    // ##################

    function grantRole(bytes32 role, address account)
        external
        onlyPerson(getRoleAdmin(role))
    {
        if (!hasRole(role, account)) {
            _roles[role].isMember[account] = true;
            _roles[role].members.push(account);
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function revokeRole(bytes32 role, address account)
        external
        onlyPerson(getRoleAdmin(role))
    {
        _removeRole(role, account);
    }

    function renounceRole(bytes32 role) external {
        _removeRole(role, msg.sender);
    }

    function abandonRole(bytes32 role) public onlyPerson(getRoleAdmin(role)) {
        delete _roles[role];
    }

    function _setRoleAdmin(bytes32 role, bytes32 admin) internal {
        require(getRoleAdmin(role) == bytes32(0), "already set role admin");

        _roles[role].admin = admin;
        emit SetRoleAdmin(role, admin);
    }

    function _removeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].isMember[account] = false;
            _roles[role].members.removeByValue(account);
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].isMember[account];
    }

    function members(bytes32 role) public view returns (address[]) {
        return _roles[role].members;
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].admin;
    }
}
