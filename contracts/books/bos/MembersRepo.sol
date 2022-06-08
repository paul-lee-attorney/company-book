/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ObjGroup.sol";
import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNParser.sol";

import "./GroupsRepo.sol";

contract MembersRepo is GroupsRepo {
    using ArrayUtils for uint32[];
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.UserGroup;

    struct Member {
        bytes32[] sharesInHand;
        uint256 parInHand;
        uint256 paidInHand;
    }

    ObjGroup.UserGroup private _shareholders;

    // mapping(uint32 => bool) public isMember;

    mapping(uint32 => Member) internal _members;

    // uint32[] private _membersList;

    uint8 public maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event SetMaxQtyOfMembers(uint8 max);

    event AddMember(uint32 indexed acct, uint256 qtyOfMembers);

    event RemoveMember(uint32 indexed acct, uint256 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sn, uint32 acct);

    event RemoveShareFromMember(bytes32 indexed sn, uint32 acct);

    event IncreaseAmountToMember(
        uint32 indexed acct,
        uint256 parValue,
        uint256 paidPar
    );

    event DecreaseAmountFromMember(
        uint32 indexed acct,
        uint256 parValue,
        uint256 paidPar
    );

    //##################
    //##    修饰器    ##s
    //##################

    modifier onlyMember() {
        require(_shareholders.isMember[_msgSender()], "NOT Member");
        _;
    }

    modifier memberExist(uint32 acct) {
        require(_shareholders.isMember[acct], "Acct is NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(uint8 max) public {
        maxQtyOfMembers = max;
    }

    function setMaxQtyOfMembers(uint8 max) external onlyOwner {
        maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(uint32 acct) internal {
        require(
            _shareholders.members.length < maxQtyOfMembers,
            "Qty of Members overflow"
        );

        if (_shareholders.addMember(acct))
            emit AddMember(acct, _shareholders.members.length);
    }

    function _removeMember(uint32 acct) internal {
        if (_shareholders.removeMember(acct)) {
            delete _members[acct];
            if (groupNo[acct] > 0) removeMemberFromGroup(acct, groupNo[acct]);
            emit RemoveMember(acct, _shareholders.members.length);
        }
    }

    function _addShareToMember(bytes6 ssn, uint32 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _increaseAmountToMember(acct, share.parValue, share.paidPar);
        _members[acct].sharesInHand.push(share.shareNumber);

        emit AddShareToMember(share.shareNumber, acct);
    }

    function _removeShareFromMember(bytes6 ssn, uint32 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Member storage member = _members[acct];
        Share storage share = _shares[ssn];

        member.sharesInHand.removeByValue(share.shareNumber);

        if (member.sharesInHand.length == 0) _removeMember(acct);
        else _decreaseAmountFromMember(acct, share.parValue, share.paidPar);

        emit RemoveShareFromMember(share.shareNumber, acct);
    }

    function _increaseAmountToMember(
        uint32 acct,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        Member storage member = _members[acct];
        member.parInHand += parValue;
        member.paidInHand += paidPar;

        emit IncreaseAmountToMember(acct, parValue, paidPar);
    }

    function _decreaseAmountFromMember(
        uint32 acct,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        Member storage member = _members[acct];

        require(member.parInHand >= parValue, "parValue over flow");
        require(member.paidInHand >= paidPar, "paidPar over flow");

        member.parInHand -= parValue;
        member.paidInHand -= paidPar;

        emit DecreaseAmountFromMember(acct, parValue, paidPar);
    }

    //##################
    //##   查询接口   ##
    //##################

    function isMember(uint32 acct) public view returns (bool) {
        return _shareholders.isMember[acct];
    }

    function membersList() external view returns (uint32[]) {
        return _shareholders.members;
    }

    function parInHand(uint32 acct)
        external
        view
        memberExist(acct)
        returns (uint256)
    {
        return _members[acct].parInHand;
    }

    function paidInHand(uint32 acct)
        external
        view
        memberExist(acct)
        returns (uint256)
    {
        return _members[acct].paidInHand;
    }

    function sharesInHand(uint32 acct)
        external
        view
        memberExist(acct)
        returns (bytes32[])
    {
        return _members[acct].sharesInHand;
    }
}
