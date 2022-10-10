// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOSCalculator {
    function membersOfClass(uint16 class) external view returns (uint40[] memory);

    function sharesOfClass(uint16 class) external view returns (bytes32[] memory);
}
