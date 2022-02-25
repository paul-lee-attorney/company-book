/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
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

    function lockContents() public;

    function setAttorney(address attorney) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAttorney() public view returns (address);
}
