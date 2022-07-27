/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAccessControl {
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
    // ##    写端口    ##
    // ##################

    function init(
        uint40 owner,
        uint40 directKeeper,
        address regCenter
    ) external;

    // function regThisContract() external;

    function abandonOwnership() external;

    function quitEntity(uint8 roleOfUser) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() external view returns (uint40);

    function getDirectKeeper() external view returns (uint40);
}
