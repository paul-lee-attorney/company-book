/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOSCalculator {
    function membersOfClass(uint8 class) external view returns (uint40[]);

    function sharesOfClass(uint8 class) external view returns (bytes32[]);
}
