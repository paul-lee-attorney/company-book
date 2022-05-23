/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAccessControl {
    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        uint32 owner,
        uint32 directKeeper,
        address usersList
    ) external;

    // function setUsersList(address ul) external;

    function abandonOwnership() external;

    function regThisContract() external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() external view returns (uint32);

    function getDirectKeeper() external view returns (uint32);
}
