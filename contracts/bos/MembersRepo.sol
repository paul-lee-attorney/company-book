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

    mapping(address => bool) public isMember;

    // 股东名册
    address[] public membersList;

    uint8 private _maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event SetMaxQtyOfMembers(uint8 max);

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
        require(isMember[msg.sender], "NOT Member");
        _;
    }

    modifier beMember(address acct) {
        require(isMember[acct], "Acct is NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(uint8 max) public {
        _maxQtyOfMembers = max;
    }

    function setMaxQtyOfMembers(uint8 max) external onlyAdmin {
        _maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(address acct) internal onlyBookeeper {
        (bool exist, ) = membersList.firstIndexOf(acct);

        if (!exist) {
            require(
                membersList.length < _maxQtyOfMembers,
                "Qty of Members overflow"
            );

            membersList.push(acct);
            isMember[acct] = true;

            emit AddMember(acct, membersList.length);
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
            membersList.removeByValue(acct);
            isMember[acct] = false;

            emit RemoveMember(acct, membersList.length);
        } else {
            _subAmountFromMember(acct, parValue, paidInAmount);
            _members[acct].sharesInHand.removeByValue(shareNumber);

            emit RemoveShareFromMember(shareNumber, acct);
        }
    }

    //##################
    //##   查询接口   ##
    //##################

    function _getMember(address acct)
        internal
        view
        beMember(acct)
        returns (
            uint256[],
            uint256,
            uint256
        )
    {
        Member storage member = _members[acct];
        return (member.sharesInHand, member.regCap, member.paidInCap);
    }
}
