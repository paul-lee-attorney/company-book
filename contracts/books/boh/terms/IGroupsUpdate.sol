// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IGroupsUpdate {
    //##################
    //##    Event     ##
    //##################
    event AddOrder(bytes32 order);

    event DelOrder(bytes32 order);

    //##################
    //##    Write     ##
    //##################

    function addOrder(bytes32 order) external;

    function delOrder(bytes32 order) external;

    //##################
    //##    Write     ##
    //##################

    function orders() external view returns (bytes32[] memory);
}
