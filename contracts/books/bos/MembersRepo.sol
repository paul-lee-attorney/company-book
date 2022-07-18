/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/Checkpoints.sol";
import "../../common/lib/SNParser.sol";

import "./GroupsRepo.sol";

contract MembersRepo is GroupsRepo {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;
    // using Checkpoints for Checkpoints.Evolution;

    // struct Member {
    //     bytes32[] sharesInHand;
    //     uint256 parInHand;
    //     uint256 paidInHand;
    // }

    EnumerableSet.UintSet private _members;

    Checkpoints.History private _qtyOfMembers;

    mapping(uint40 => EnumerableSet.Bytes32Set) internal _sharesInHand;

    mapping(uint40 => Checkpoints.History) private _votesInHand;

    uint8 private _maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event SetMaxQtyOfMembers(uint8 max);

    event AddMember(uint40 indexed acct, uint256 qtyOfMembers);

    event RemoveMember(uint40 indexed acct, uint256 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sn, uint40 acct);

    event RemoveShareFromMember(bytes32 indexed sn, uint40 acct);

    event IncreaseAmountToMember(
        uint40 indexed acct,
        uint256 parValue,
        uint256 paidPar,
        uint256 blocknumber
    );

    event DecreaseAmountFromMember(
        uint40 indexed acct,
        uint256 parValue,
        uint256 paidPar,
        uint256 blocknumber
    );

    //##################
    //##    修饰器    ##s
    //##################

    modifier onlyMember() {
        require(_members.contains(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_members.contains(acct), "Acct is NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(uint8 max) public {
        _maxQtyOfMembers = max;
    }

    function setMaxQtyOfMembers(uint8 max) external onlyOwner {
        _maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(uint40 acct, uint64 parValue) internal {
        require(
            _members.length() < _maxQtyOfMembers,
            "Qty of Members overflow"
        );

        if (_members.add(acct)) {
            _rc.investIn(acct, parValue, true);
            _qtyOfMembers.push(_members.length(), 1);
            emit AddMember(acct, _members.length());
        }
    }

    function _removeMember(uint40 acct) internal {
        if (_members.remove(acct)) {
            delete _sharesInHand[acct];
            if (_groupNo[acct] > 0) removeMemberFromGroup(acct, _groupNo[acct]);
            _qtyOfMembers.push(_members.length(), 0);
            _rc.exitOut(acct);
            emit RemoveMember(acct, _members.length());
        }
    }

    function _addShareToMember(bytes6 ssn, uint40 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _increaseAmountToMember(acct, share.parValue, share.paidPar);
        _sharesInHand[acct].add(share.shareNumber);

        emit AddShareToMember(share.shareNumber, acct);
    }

    function _removeShareFromMember(bytes6 ssn, uint40 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _sharesInHand[acct].remove(share.shareNumber);

        if (_sharesInHand[acct].length() == 0) _removeMember(acct);
        else _decreaseAmountFromMember(acct, share.parValue, share.paidPar);

        emit RemoveShareFromMember(share.shareNumber, acct);
    }

    function _increaseAmountToMember(
        uint40 acct,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        (uint256 oldPar, uint256 oldPaid) = _votesInHand[acct].latest();

        uint256 blocknumber = _votesInHand[acct].push(
            oldPar + parValue,
            oldPaid + paidPar
        );

        _rc.updateParValue(acct, uint64(oldPar + parValue));

        emit IncreaseAmountToMember(acct, parValue, paidPar, blocknumber);
    }

    function _decreaseAmountFromMember(
        uint40 acct,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        (uint256 oldPar, uint256 oldPaid) = _votesInHand[acct].latest();

        require(oldPar >= parValue, "parValue over flow");
        require(oldPaid >= paidPar, "paidPar over flow");

        uint256 blocknumber = _votesInHand[acct].push(
            oldPar - parValue,
            oldPaid - paidPar
        );

        _rc.updateParValue(acct, uint64(oldPar - parValue));

        emit DecreaseAmountFromMember(acct, parValue, paidPar, blocknumber);
    }

    //##################
    //##   查询接口   ##
    //##################

    function maxQtyOfMembers() external view onlyUser returns (uint8) {
        return _maxQtyOfMembers;
    }

    function isMember(uint40 acct) public view onlyUser returns (bool) {
        return _members.contains(acct);
    }

    function members() external view onlyUser returns (uint40[]) {
        return _members.valuesToUint40();
    }

    function qtyOfmembersAtBlock(uint256 blockNumber)
        external
        view
        onlyUser
        returns (uint256 qty)
    {
        (qty, ) = _qtyOfMembers.getAtBlock(blockNumber);
    }

    function parInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (uint256 par)
    {
        (par, ) = _votesInHand[acct].latest();
    }

    function paidInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (uint256 paid)
    {
        (, paid) = _votesInHand[acct].latest();
    }

    function voteInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (uint256 vote)
    {
        if (_getSHA().basedOnPar()) (vote, ) = _votesInHand[acct].latest();
        else (, vote) = _votesInHand[acct].latest();
    }

    function votesAtBlock(uint40 acct, uint256 blockNumber)
        external
        view
        onlyUser
        returns (uint256 vote)
    {
        if (_getSHA().basedOnPar())
            (vote, ) = _votesInHand[acct].getAtBlock(blockNumber);
        else (, vote) = _votesInHand[acct].getAtBlock(blockNumber);
    }

    function sharesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (bytes32[])
    {
        return _sharesInHand[acct].values();
    }
}
