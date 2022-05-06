/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "./GroupsRepo.sol";

contract MembersRepo is GroupsRepo {
    using ArrayUtils for address[];
    using ShareSNParser for bytes32;

    mapping(address => bool) public isMember;

    mapping(address => bytes32[]) public sharesInHand;

    // 股东名册
    address[] private _membersList;

    uint8 public maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event SetMaxQtyOfMembers(uint8 max);
    event AddMember(address indexed acct, uint256 qtyOfMembers);
    event RemoveMember(address indexed acct, uint256 qtyOfMembers);
    event SetGroupNo(address acct, uint8 groupNo);

    //##################
    //##    修饰器    ##s
    //##################

    modifier onlyMember() {
        require(isMember[msg.sender], "NOT Member");
        _;
    }

    modifier memberExist(address acct) {
        require(isMember[acct], "Acct is NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(uint8 max) public {
        maxQtyOfMembers = max;
    }

    function setMaxQtyOfMembers(uint8 max) external onlyAdmin {
        maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(address acct) internal {
        (bool exist, ) = _membersList.firstIndexOf(acct);

        if (!exist) {
            require(
                _membersList.length < maxQtyOfMembers,
                "Qty of Members overflow"
            );

            _membersList.push(acct);
            isMember[acct] = true;

            emit AddMember(acct, _membersList.length);
        }
    }

    function _removeMember(address acct) internal {
        _membersList.removeByValue(acct);
        isMember[acct] = false;

        if (groupNo[acct] > 0) removeMemberFromGroup(acct, groupNo[acct]);

        emit RemoveMember(acct, _membersList.length);
    }

    function _addShareToMember(bytes6 ssn, address acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        sharesInHand[acct].push(_shares[ssn].shareNumber);
    }

    function _removeShareFromMember(bytes6 ssn, address acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        sharesInHand[acct].removeByValue(_shares[ssn].shareNumber);
    }

    function _updateMembersList(address acct) internal {
        uint256 len = _snList.length;
        bool flag;

        for (uint256 i = 0; i < len; i++) {
            if (acct == _snList[i].shareholder()) {
                flag = true;
                break;
            }
        }

        if (!flag) _removeMember(acct);
    }

    function setGroupNo(address acct, uint8 group) external onlyKeeper {
        require(group > 0, "ZERO group");
        require(group <= counterOfGroups + 1, "group OVER FLOW");

        if (group > counterOfGroups) counterOfGroups = group;

        groupNo[acct] = group;

        emit SetGroupNo(acct, group);
    }

    //##################
    //##   查询接口   ##
    //##################

    function membersList() external view returns (address[]) {
        return _membersList;
    }
}
