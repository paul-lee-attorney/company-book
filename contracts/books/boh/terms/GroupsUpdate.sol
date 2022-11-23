// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/EnumerableSet.sol";

import "../../../common/ruting/ROMSetting.sol";

import "./IGroupsUpdate.sol";

contract GroupsUpdate is IGroupsUpdate, ROMSetting {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private _orders;

    //##################
    //##    写接口    ##
    //##################

    function addOrder(bytes32 order) external onlyAttorney {
        if (_orders.add(order)) emit AddOrder(order);
    }

    function delOrder(bytes32 order) external onlyAttorney {
        if (_orders.remove(order)) emit DelOrder(order);
    }

    //##################
    //##    读接口    ##
    //##################

    function orders() external view returns (bytes32[] memory) {
        return _orders.values();
    }
}
