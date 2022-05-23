/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library SequenceList {
    using ArrayUtils for uint16[];

    struct List {
        mapping(uint16 => bool) isIn;
        uint16[] items;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addItem(List storage list, uint16 sequence)
        internal
        returns (bool flag)
    {
        if (!list.isIn[sequence]) {
            list.isIn[sequence] = true;
            list.items.push(sequence);
            flag = true;
        } else flag = false;
    }

    function removeItem(List storage list, uint16 sequence)
        internal
        returns (bool flag)
    {
        if (list.isIn[sequence]) {
            list.isIn[sequence] = false;
            list.items.removeByValue(sequence);
            flag = true;
        } else flag = false;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isItem(List storage list, uint16 sequence)
        internal
        view
        returns (bool)
    {
        return list.isIn[sequence];
    }

    function qtyOfItems(List storage list) internal view returns (uint256) {
        return list.items.length;
    }

    function getItems(List storage list) internal view returns (uint16[]) {
        return list.items;
    }
}
