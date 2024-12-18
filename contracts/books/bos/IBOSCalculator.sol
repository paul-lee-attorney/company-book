/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOSCalculator {
    function membersOfClass(uint8 class) external view returns (uint40[]);

    function sharesOfClass(uint8 class) external view returns (bytes32[]);

    function parOfGroup(uint16 group) external view returns (uint64 parValue);

    function paidOfGroup(uint16 group) external view returns (uint64 paidPar);

    function updateController(bool basedOnPar) external;
}
