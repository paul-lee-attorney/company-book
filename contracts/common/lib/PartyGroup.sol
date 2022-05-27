/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library PartyGroup {
    using ArrayUtils for uint32[];

    struct Group {
        mapping(uint32 => uint16) _counterOfParty;
        uint16 _counter;
        mapping(uint32 => bool) _isJoined;
        uint32[] _parties;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addParty(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        group._counterOfParty[acct]++;
        group._counter++;

        if (!group._isJoined[acct]) {
            group._isJoined[acct] = true;
            group._parties.push(acct);
            flag = true;
        }
    }

    function removeParty(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        if (group._isJoined[acct]) {
            group._isJoined[acct] = false;
            group._parties.removeByValue(acct);

            group._counter -= group._counterOfParty[acct];
            group._counterOfParty[acct] = 0;

            flag = true;
        }
    }

    function resetCounter(Group storage group) internal {
        uint256 len = group._parties.length;
        for (uint256 i = 0; i < len; i++)
            group._counterOfParty[group._parties[i]] = 1;

        group._counter = uint16(len);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isParty(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group._isJoined[acct];
    }

    function counterOfParty(Group storage group, uint32 acct)
        internal
        view
        returns (uint16)
    {
        return group._counterOfParty[acct];
    }

    function qtyOfParties(Group storage group) internal view returns (uint256) {
        return group._parties.length;
    }

    function counterOfParties(Group storage group)
        internal
        view
        returns (uint16)
    {
        return group._counter;
    }

    function getParty(Group storage group, uint256 index)
        internal
        view
        returns (uint32)
    {
        return group._parties[index];
    }

    function parties(Group storage group) internal view returns (uint32[]) {
        return group._parties;
    }
}
