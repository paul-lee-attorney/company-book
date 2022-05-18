/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library UserGroup {
    using ArrayUtils for address[];

    struct Group {
        mapping(address => bool) isJoined;
        address[] members;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addMember(Group storage group, address acct)
        internal
        returns (bool flag)
    {
        if (!group.isJoined[acct]) {
            group.isJoined[acct] = true;
            group.members.push(acct);
            flag = true;
        } else flag = false;
    }

    function removeMember(Group storage group, address acct)
        internal
        returns (bool flag)
    {
        if (group.isJoined[acct]) {
            group.isJoined[acct] = false;
            group.members.removeByValue(acct);
            flag = true;
        } else flag = false;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isMember(Group storage group, address acct)
        internal
        view
        returns (bool)
    {
        return group.isJoined[acct];
    }

    function qtyOfMembers(Group storage group) internal view returns (uint256) {
        return group.members.length;
    }

    function members(Group storage group) internal view returns (address[]) {
        return group.members;
    }
}
