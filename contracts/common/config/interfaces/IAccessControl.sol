/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAccessControl {
    // ##################
    // ##    写端口    ##
    // ##################

    function init(address owner, address directKeeper) external;

    function abandonOwnership() external;

    // ##################
    // ##   查询端口   ##
    // ##################
    function isOwner(address acct) external view returns (bool);

    function getOwner() external view returns (address);

    function isDirectKeeper(address acct) external view returns (bool);

    function getDirectKeeper() external view returns (address);
}
