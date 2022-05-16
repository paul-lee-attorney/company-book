/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IDraftSetting {
    // ##################
    // ##   Event      ##
    // ##################

    event SetAttorney(address attorney);

    event LockContents();

    // ##################
    // ##   设置端口   ##
    // ##################

    function lockContents() external;

    function setAttorney(address attorney) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAttorney() external view returns (address);
}
