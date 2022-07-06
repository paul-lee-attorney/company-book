/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IGroupsUpdate {
    //##################
    //##    Event     ##
    //##################
    event AddMemberOrder(uint40 acct, uint16 groupNo);

    event RemoveMemberOrder(uint40 acct, uint16 groupNo);

    event DelOrder(bytes32 order);

    //##################
    //##    Write     ##
    //##################

    function addMemberOrder(uint40 acct, uint16 groupNo) external;

    function removeMemberOrder(uint40 acct, uint16 groupNo) external;

    function delOrder(bytes32 order) external;

    function orders() external view returns (bytes32[]);
}
