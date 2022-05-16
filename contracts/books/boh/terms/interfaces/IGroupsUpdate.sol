/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IGroupsUpdate {
    function addMemberOrder(address acct, uint16 groupNo) external;

    function removeMemberOrder(address acct, uint16 groupNo) external;

    function delOrder(bytes32 order) external;

    function orders() external view returns (bytes32[]);
}
