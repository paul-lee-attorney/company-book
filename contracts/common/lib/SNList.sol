/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";
import "./SNParser.sol";

library SNList {
    using ArrayUtils for bytes32[];
    using SNParser for bytes32;

    struct List {
        mapping(bytes6 => bool) isItem;
        bytes32[] items;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addItem(List storage list, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (!list.isItem[sn.short()]) {
            list.isItem[sn.short()] = true;
            sn.insertToQue(list.items);
            flag = true;
        }
    }

    function removeItem(List storage list, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (list.isItem[sn.short()]) {
            list.isItem[sn.short()] = false;
            list.items.removeByValue(sn);
            flag = true;
        }
    }
}
