/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "./SharesRepo.sol";

contract MembersRepo is SharesRepo {
    using SafeMath for uint256;
    using ArrayUtils for uint256[];
    using ArrayUtils for address[];

    // 股东
    struct Member {
        uint256[] sharesInHand; //持有的股票编号
        uint256 regCap; //注册资本
        uint256 paidInCap; //实缴资本
    }

    // 账号 => 股东 映射
    mapping(address => Member) private _members;
    mapping(address => bool) private _isMemberAdd;

    // 股东名册
    address[] private _memberList;

    uint8 private _maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event AddMember(address indexed acct, uint256 qtyOfMembers);
    event RemoveMember(address indexed acct, uint256 qtyOfMembers);

    event AddShareToMember(uint256 indexed shareNumber, address indexed acct);
    event RemoveShareFromMember(
        uint256 indexed shareNumber,
        address indexed acct
    );

    event PayInCapitalToMember(address indexed acct, uint256 amount);
    event SubAmountFromMember(
        address indexed acct,
        uint256 parValue,
        uint256 paidInAmount
    );

    //##################
    //##    修饰器    ##
    //##################

    modifier onlyMember() {
        require(_isMemberAdd[msg.sender], "仅 股东 可操作");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(uint8 max) public {
        _maxQtyOfMembers = max;
    }

    function _addMember(address acct) internal onlyBookeeper {
        (bool exist, ) = _memberList.firstIndexOf(acct);

        if (!exist) {
            require(_memberList.length < _maxQtyOfMembers, "股东人数溢出");

            _memberList.push(acct);
            _isMemberAdd[acct] = true;

            emit AddMember(acct, _memberList.length);
        }
    }

    function _addShareToMember(
        address acct,
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) internal onlyBookeeper {
        _members[acct].sharesInHand.push(shareNumber);
        _members[acct].regCap = _members[acct].regCap.add(parValue);
        _members[acct].paidInCap = _members[acct].paidInCap.add(paidInAmount);

        emit AddShareToMember(shareNumber, acct);
    }

    function _payInCapitalToMember(address acct, uint256 amount)
        internal
        onlyBookeeper
    {
        _members[acct].paidInCap += amount;

        emit PayInCapitalToMember(acct, amount);
    }

    function _subAmountFromMember(
        address acct,
        uint256 parValue,
        uint256 paidInAmount
    ) internal onlyBookeeper {
        _members[acct].regCap -= parValue;
        _members[acct].paidInCap -= paidInAmount;

        emit SubAmountFromMember(acct, parValue, paidInAmount);
    }

    function _removeShareFromMember(
        address acct,
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) internal onlyBookeeper {
        if (_members[acct].regCap == parValue) {
            delete _members[acct];
            _memberList.removeByValue(acct);
            _isMemberAdd[acct] = false;

            emit RemoveMember(acct, _memberList.length);
        } else {
            _subAmountFromMember(acct, parValue, paidInAmount);
            _members[acct].sharesInHand.removeByValue(shareNumber);

            emit RemoveShareFromMember(shareNumber, acct);
        }
    }

    //##################
    //##   查询接口   ##
    //##################

    function _isMember(address acct) internal view returns (bool) {
        return _isMemberAdd[acct];
    }

    function _getMember(address acct)
        internal
        view
        returns (
            uint256[],
            uint256,
            uint256
        )
    {
        require(_isMemberAdd[acct], "目标股东不存在");
        Member storage member = _members[acct];
        return (member.sharesInHand, member.regCap, member.paidInCap);
    }

    function _getMemberList() internal view returns (address[]) {
        require(_memberList.length > 0, "股东人数为0");
        return _memberList;
    }

    function _getQtyOfMembers() internal view returns (uint256) {
        return _memberList.length;
    }
}
