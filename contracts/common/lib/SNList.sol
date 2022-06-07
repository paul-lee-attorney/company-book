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
        mapping(bytes6 => bool) _isItem;
        bytes32[] _snList;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addItem(List storage list, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (!list._isItem[sn.short()]) {
            list._isItem[sn.short()] = true;
            sn.insertToQue(list._snList);
            flag = true;
        }
    }

    function removeItem(List storage list, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (list._isItem[sn.short()]) {
            list._isItem[sn.short()] = false;
            list._snList.removeByValue(sn);
            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isItem(List storage list, bytes6 ssn)
        internal
        view
        returns (bool)
    {
        return list._isItem[ssn];
    }

    function qtyOfItems(List storage list) internal view returns (uint256) {
        return list._snList.length;
    }

    function snList(List storage list) internal view returns (bytes32[]) {
        return list._snList;
    }
}
