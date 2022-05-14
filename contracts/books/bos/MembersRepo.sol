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

    struct Member {
        bytes32[] sharesInHand;
        uint256 parInHand;
        uint256 paidInHand;
    }

    mapping(address => bool) public isMember;

    mapping(address => Member) internal _members;

    address[] private _membersList;

    uint8 public maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event SetMaxQtyOfMembers(uint8 max);

    event AddMember(address indexed acct, uint256 qtyOfMembers);

    event RemoveMember(address indexed acct, uint256 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sn, address acct);

    event RemoveShareFromMember(bytes32 indexed sn, address acct);

    event IncreaseAmountToMember(
        address indexed acct,
        uint256 parValue,
        uint256 paidPar
    );

    event DecreaseAmountFromMember(
        address indexed acct,
        uint256 parValue,
        uint256 paidPar
    );

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
        if (!isMember[acct]) {
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

        delete _members[acct];

        delete isMember[acct];

        if (groupNo[acct] > 0) removeMemberFromGroup(acct, groupNo[acct]);

        emit RemoveMember(acct, _membersList.length);
    }

    function _addShareToMember(bytes6 ssn, address acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _increaseAmountToMember(acct, share.parValue, share.paidPar);
        _members[acct].sharesInHand.push(share.shareNumber);

        emit AddShareToMember(share.shareNumber, acct);
    }

    function _removeShareFromMember(bytes6 ssn, address acct)
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
        address acct,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        Member storage member = _members[acct];
        member.parInHand += parValue;
        member.paidInHand += paidPar;

        emit IncreaseAmountToMember(acct, parValue, paidPar);
    }

    function _decreaseAmountFromMember(
        address acct,
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

    // function _updateMembersList(address acct) internal {
    //     uint256 len = _snList.length;
    //     bool flag;

    //     for (uint256 i = 0; i < len; i++) {
    //         if (acct == _snList[i].shareholder()) {
    //             flag = true;
    //             break;
    //         }
    //     }

    //     if (!flag) _removeMember(acct);
    // }

    //##################
    //##   查询接口   ##
    //##################

    function membersList() external view returns (address[]) {
        return _membersList;
    }

    function parInHand(address acct)
        external
        view
        memberExist(acct)
        returns (uint256)
    {
        return _members[acct].parInHand;
    }

    function paidInHand(address acct)
        external
        view
        memberExist(acct)
        returns (uint256)
    {
        return _members[acct].paidInHand;
    }

    function sharesInHand(address acct)
        external
        view
        memberExist(acct)
        returns (bytes32[])
    {
        return _members[acct].sharesInHand;
    }
}
