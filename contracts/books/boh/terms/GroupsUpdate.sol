// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";

import "../../../common/ruting/ROMSetting.sol";

import "./IGroupsUpdate.sol";

contract GroupsUpdate is IGroupsUpdate, ROMSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private _orders;

    //##################
    //##    写接口    ##
    //##################

    function _createOrder(
        bool addMember,
        uint40 acct,
        uint16 groupNo
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.boolToSN(0, addMember);
        _sn = _sn.sequenceToSN(1, groupNo);
        _sn = _sn.acctToSN(3, acct);

        return _sn.bytesToBytes32();
    }

    function addMemberOrder(uint40 acct, uint16 groupNo) external onlyAttorney {
        require(groupNo > 0, "ZERO groupNo");
        require(groupNo <= _rom.counterOfGroups() + 1, "groupNo OVER FLOW");

        bool addMember = true;

        bytes32 order = _createOrder(addMember, acct, groupNo);

        if (_orders.add(order)) emit AddMemberOrder(acct, groupNo);
    }

    function removeMemberOrder(uint40 acct, uint16 groupNo)
        external
        memberExist(acct)
        onlyAttorney
    {
        require(_rom.isGroup(groupNo), "groupNo NOT EXIST");
        require(_rom.groupNo(acct) == groupNo, "WRONG group number");

        bool addMember = false;

        bytes32 order = _createOrder(addMember, acct, groupNo);
        if (_orders.add(order)) emit RemoveMemberOrder(acct, groupNo);
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
