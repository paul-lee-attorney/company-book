/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IBookOfConcerted.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/ruting/BOSSetting.sol";

contract BookOfConcerted is IBookOfConcerted, BOSSetting {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Group {
        EnumerableSet.UintSet affiliates;
        uint64 votesInHand;
    }

    mapping(uint16 => Group) private _groups;

    // mapping(uint40 => uint16) private _groupNo;

    EnumerableSet.UintSet private _groupNumbersList;

    // uint16 private _controller;

    uint16 private _counterOfGroups;

    //##################
    //##   Modifier   ##
    //##################

    modifier groupExist(uint16 group) {
        require(_groupNumbersList.contains(group), "group is NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function addMemberToGroup(uint40 acct, uint16 group) external onlyKeeper {
        require(group > 0, "BOC.addMemberToGroup: ZERO group");
        require(
            group <= _counterOfGroups + 1,
            "BOC.addMemberToGroup: group OVER FLOW"
        );
        require(
            _bos.groupNo(acct) == 0,
            "BOC.addMemberToGroup: acct already in a group"
        );

        _groupNumbersList.add(group);

        if (group > _counterOfGroups) _counterOfGroups++;

        // _groupNo[acct] = group;

        _groups[group].affiliates.add(acct);
        _groups[group].votesInHand += _bos.votesInHand(acct);

        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(uint40 acct, uint16 group)
        public
        groupExist(group)
        onlyKeeper
    {
        require(
            _bos.groupNo(acct) == group,
            "BOC.removeMemberFromGroup: WRONG group number"
        );

        _groups[group].affiliates.remove(acct);
        _groups[group].votesInHand -= _bos.votesInHand(acct);

        // _groupNo[acct] = 0;

        if (_groups[group].affiliates.length() == 0) {
            _groupNumbersList.remove(group);
        }

        emit RemoveMemberFromGroup(acct, group);
    }

    function setController(uint16 group) external onlyKeeper groupExist(group) {
        if (_controller != group) {
            _controller = group;
            emit SetController(group);
        }
    }

    function updateController(bool basedOnPar) external onlyKeeper {
        _controller = _findControllor(basedOnPar);
    }

    function _findControllor(bool basedOnPar)
        private
        view
        returns (uint16 index)
    {
        uint16[] memory groups = _groupNumbersList.valuesToUint16();

        uint256 len = groups.length;

        index = _controller;

        uint64 amount;
        uint64 amt;
        uint16 i;

        if (basedOnPar) {
            amount = parOfGroup(index);
            for (i = 0; i < len; i++) {
                if (i == index) continue;
                else {
                    amt = parOfGroup(groups[i]);
                    if (amt > amount) {
                        index = i;
                        amount = amt;
                    }
                }
            }
        } else {
            amount = paidOfGroup(index);
            for (i = 0; i < len; i++) {
                if (i == index) continue;
                else {
                    amt = paidOfGroup(groups[i]);
                    if (amt > amount) {
                        index = i;
                        amount = amt;
                    }
                }
            }
        }
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    function counterOfGroups() external view returns (uint16) {
        return _counterOfGroups;
    }

    function controller() external view returns (uint16) {
        return _controller;
    }

    function groupNo(uint40 acct) external view returns (uint16) {
        return _groupNo[acct];
    }

    function affiliatesOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint40[])
    {
        return _groups[group].affiliates.valuesToUint40();
    }

    function isGroup(uint16 group) external view returns (bool) {
        return _groupNumbersList.contains(group);
    }

    function belongsToGroup(uint40 acct, uint16 group)
        external
        view
        groupExist(group)
        returns (bool)
    {
        require(acct > 0, "BOC.belongsToGroup: zero acct");
        return _groups[group].affiliates.contains(acct);
    }

    function snList() external view returns (uint16[]) {
        return _groupNumbersList.valuesToUint16();
    }

    function parOfGroup(uint16 group)
        public
        view
        groupExist(group)
        returns (uint64 parValue)
    {
        uint40[] memory members = _groups[group].affiliates.valuesToUint40();

        uint256 len = members.length;

        while (len > 0) {
            if (_bos.isMember(members[len - 1])) {
                parValue += _bos.parInHand(members[len - 1]);
            }
            len--;
        }
    }

    function paidOfGroup(uint16 group)
        public
        view
        groupExist(group)
        returns (uint64 paidPar)
    {
        uint40[] memory members = _groups[group].affiliates.valuesToUint40();

        uint256 len = members.length;

        while (len > 0) {
            if (_bos.isMember(members[len - 1])) {
                paidPar += _bos.paidInHand(members[len - 1]);
            }
            len--;
        }
    }
}
