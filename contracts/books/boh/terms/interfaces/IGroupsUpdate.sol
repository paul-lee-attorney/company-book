/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IGroupsUpdate {
    function addMemberOrder(uint32 acct, uint16 groupNo) external;

    function removeMemberOrder(uint32 acct, uint16 groupNo) external;

    function delOrder(bytes32 order) external;

    function orders() external view returns (bytes32[]);
}
