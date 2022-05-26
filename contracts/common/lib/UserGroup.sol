/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library UserGroup {
    using ArrayUtils for uint32[];

    struct Group {
        mapping(uint32 => uint16) _counterOfMember;
        mapping(uint32 => bool) _isJoined;
        uint32[] _members;
        uint16 _counter;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addMember(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        group._counterOfMember[acct]++;
        group._counter++;
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
            group._counter -= group._counterOfMember[acct];
            group._counterOfMember[acct] = 0;
        }
    }

    function resetCounter(Group storage group) internal returns (bool flag) {
        uint256 len = group._members.length;
        for (uint256 i = 0; i < len; i++)
            group._counterOfMember[group._members[i]] = 1;

        group._counter = uint16(group._members.length);
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

    function counterOfMember(Group storage group, uint32 acct)
        internal
        view
        returns (uint16)
    {
        return group._counterOfMember[acct];
    }

    function qtyOfMembers(Group storage group) internal view returns (uint256) {
        return group._members.length;
    }

    function counterOfMembers(Group storage group)
        internal
        view
        returns (uint16)
    {
        return group._counter;
    }

    function members(Group storage group) internal view returns (uint32[]) {
        return group._members;
    }
}
