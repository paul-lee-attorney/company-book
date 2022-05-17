/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IDraftControl {
    // ##################
    // ##    写端口    ##
    // ##################

    function setGeneralCounsel(address gc) external;

    function lockContents() external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() external view returns (address);

    function getDirectKeeper() external view returns (address);
}
