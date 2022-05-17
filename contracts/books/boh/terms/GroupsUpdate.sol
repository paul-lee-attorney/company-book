/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/serialNumber/SNFactory.sol";

import "../../../common/config/BOSSetting.sol";
import "../../../common/config/DraftControl.sol";

contract GroupsUpdate is BOSSetting, DraftControl {
    using SNFactory for bytes;
    using SNFactory for bytes32;
    using ArrayUtils for bytes32[];

    bytes32[] private _orders;

    //##################
    //##    Event     ##
    //##################
    event AddMemberOrder(address acct, uint16 groupNo);
    event RemoveMemberOrder(address acct, uint16 groupNo);
    event DelOrder(bytes32 order);

    //##################
    //##    写接口    ##
    //##################

    function _createOrder(
        bool addMember,
        address acct,
        uint16 groupNo
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.boolToSN(0, addMember);
        _sn = _sn.sequenceToSN(1, groupNo);
        _sn = _sn.addrToSN(3, acct);

        return _sn.bytesToBytes32();
    }

    function addMemberOrder(address acct, uint16 groupNo)
        external
        onlyAttorney
    {
        require(groupNo > 0, "ZERO groupNo");
        require(groupNo <= _bos.counterOfGroups() + 1, "groupNo OVER FLOW");

        bool addMember = true;

        bytes32 order = _createOrder(addMember, acct, groupNo);
        order.insertToQue(_orders);

        emit AddMemberOrder(acct, groupNo);
    }

    function removeMemberOrder(address acct, uint16 groupNo)
        external
        memberExist(acct)
        onlyAttorney
    {
        require(_bos.isGroup(groupNo), "groupNo NOT EXIST");
        require(_bos.groupNo(acct) == groupNo, "WRONG group number");

        bool addMember = false;

        bytes32 order = _createOrder(addMember, acct, groupNo);
        order.insertToQue(_orders);

        emit RemoveMemberOrder(acct, groupNo);
    }

    function delOrder(bytes32 order) external onlyAttorney {
        _orders.removeByValue(order);

        emit DelOrder(order);
    }

    //##################
    //##    读接口    ##
    //##################

    function orders() external view returns (bytes32[]) {
        return _orders;
    }
}
