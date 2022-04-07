/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface ITerm {
    // ##################
    // ##   设置端口   ##
    // ##################

    function isTriggered(address ia, uint8 sn) external view returns (bool);

    function isExempted(address ia, uint8 sn) external view returns (bool);
}
