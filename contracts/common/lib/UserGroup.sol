/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library UserGroup {
    using ArrayUtils for uint32[];

    struct Group {
        mapping(uint32 => bool) _isJoined;
        uint32[] _members;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addMember(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        if (!group._isJoined[acct]) {
            group._isJoined[acct] = true;
            group._members.push(acct);
            flag = true;
        }
    }

    function removeMember(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        if (group._isJoined[acct]) {
            group._isJoined[acct] = false;
            group._members.removeByValue(acct);
            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isMember(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group._isJoined[acct];
    }

    function qtyOfMembers(Group storage group) internal view returns (uint256) {
        return group._members.length;
    }

    function getMember(Group storage group, uint256 index)
        internal
        view
        returns (uint32)
    {
        return group._members[index];
    }

    function members(Group storage group) internal view returns (uint32[]) {
        return group._members;
    }
}
