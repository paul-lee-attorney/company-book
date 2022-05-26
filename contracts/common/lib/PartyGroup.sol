/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./UserGroup.sol";

library PartyGroup {
    using UserGroup for UserGroup.Group;

    struct Group {
        mapping(uint32 => uint16) _counterOfParty;
        uint16 _counter;
        UserGroup.Group _parties;
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
        flag = group._parties.addMember(acct);
    }

    function removeParty(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        if (group._parties.removeMember(acct)) {
            group._counter -= group._counterOfParty[acct];
            group._counterOfParty[acct] = 0;
            flag = true;
        }
    }

    function resetCounter(Group storage group) internal {
        uint256 len = group._parties.qtyOfMembers();
        for (uint256 i = 0; i < len; i++)
            group._counterOfParty[group._parties.getMember(i)] = 1;

        group._counter = uint16(group._parties.qtyOfMembers());
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isParty(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group._parties.isMember(acct);
    }

    function counterOfParty(Group storage group, uint32 acct)
        internal
        view
        returns (uint16)
    {
        return group._counterOfParty[acct];
    }

    function qtyOfParties(Group storage group) internal view returns (uint256) {
        return group._parties.qtyOfMembers();
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
        return group._parties.getMember(index);
    }

    function parties(Group storage group) internal view returns (uint32[]) {
        return group._parties.members();
    }
}
