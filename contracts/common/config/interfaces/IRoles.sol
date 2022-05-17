/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IRoles {
    // ##################
    // ##    写端口    ##
    // ##################

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;

    function abandonRole(bytes32 role) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function members(bytes32 role) external view returns (address[]);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);
}
