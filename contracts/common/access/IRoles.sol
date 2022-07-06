/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IRoles {
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

    function grantRole(bytes32 role, uint40 account) external;

    function revokeRole(bytes32 role, uint40 account) external;

    function renounceRole(bytes32 role) external;

    function abandonRole(bytes32 role) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function hasRole(bytes32 role, uint40 account) external view returns (bool);

    function members(bytes32 role) external view returns (uint40[]);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);
}
