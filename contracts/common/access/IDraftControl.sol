/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IDraftControl {
    // ##################
    // ##   Event      ##
    // ##################

    event SetGeneralCounsel(uint40 indexed gc);

    event LockContents();

    // ##################
    // ##    写端口    ##
    // ##################

    function setGeneralCounsel(address gc) external;

    function lockContents() external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function finalized() external returns (bool);

    function ATTORNEYS() external returns (bytes32);

    function getGC() external view returns (uint40);
}
