/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library AddrGroup {
    using ArrayUtils for address[];

    struct Group {
        mapping(address => bool) _isJoined;
        address[] _members;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addMember(Group storage book, address addr)
        internal
        returns (bool flag)
    {
        if (!book._isJoined[addr]) {
            book._isJoined[addr] = true;
            book._members.push(addr);
            flag = true;
        }
    }

    function removeMember(Group storage book, address addr)
        internal
        returns (bool flag)
    {
        if (book._isJoined[addr]) {
            book._isJoined[addr] = false;
            book._members.removeByValue(addr);
            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isMember(Group storage book, address addr)
        internal
        view
        returns (bool)
    {
        return book._isJoined[addr];
    }

    function qtyOfMembers(Group storage book) internal view returns (uint256) {
        return book._members.length;
    }

    function getMember(Group storage book, uint256 index)
        internal
        view
        returns (address)
    {
        return book._members[index];
    }

    function members(Group storage book) internal view returns (address[]) {
        return book._members;
    }
}
