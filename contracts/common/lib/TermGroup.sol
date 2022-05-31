/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library TermGroup {
    using ArrayUtils for uint8[];

    struct Group {
        mapping(uint8 => bool) _isIncluded;
        uint8[] _terms;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addTerm(Group storage group, uint8 title)
        internal
        returns (bool flag)
    {
        if (!group._isIncluded[title]) {
            group._isIncluded[title] = true;
            group._terms.push(title);
            flag = true;
        }
    }

    function removeTerm(Group storage group, uint8 title)
        internal
        returns (bool flag)
    {
        if (group._isIncluded[title]) {
            group._isIncluded[title] = false;
            group._terms.removeByValue(title);
            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isTerm(Group storage group, uint8 title)
        internal
        view
        returns (bool)
    {
        return group._isIncluded[title];
    }

    function qtyOfTerms(Group storage group) internal view returns (uint256) {
        return group._terms.length;
    }

    function getTerm(Group storage group, uint256 index)
        internal
        view
        returns (uint8)
    {
        return group._terms[index];
    }

    function terms(Group storage group) internal view returns (uint8[]) {
        return group._terms;
    }
}
