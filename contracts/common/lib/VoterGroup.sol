/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library VoterGroup {
    using ArrayUtils for uint32[];

    struct Group {
        mapping(uint32 => uint32) _sigDate;
        mapping(uint32 => bytes32) _sigHash;
        mapping(uint32 => uint256) _amtOfVoter;
        uint256 _sumOfAmt;
        uint32[] _voters;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addVote(
        Group storage group,
        uint32 acct,
        uint256 amount,
        uint32 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        if (group._sigDate[acct] == 0) {
            group._sigDate[acct] = sigDate;
            group._sigHash[acct] = sigHash;
            group._amtOfVoter[acct] = amount;
            group._sumOfAmt += amount;
            group._voters.push(acct);
            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isVoter(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group._sigDate[acct] > 0;
    }

    function sigDate(Group storage group, uint32 acct)
        internal
        view
        returns (uint32)
    {
        require(group._sigDate[acct] > 0, "not a voter");

        return group._sigDate[acct];
    }

    function sigHash(Group storage group, uint32 acct)
        internal
        view
        returns (bytes32)
    {
        require(group._sigDate[acct] > 0, "not a voter");

        return group._sigHash[acct];
    }

    function sigVerify(
        Group storage group,
        uint32 acct,
        string src
    ) internal view returns (bool) {
        require(group._sigDate[acct] > 0, "not a voter");

        return group._sigHash[acct] == keccak256(bytes(src));
    }

    function qtyOfVoters(Group storage group) internal view returns (uint256) {
        return group._voters.length;
    }

    function getVoter(Group storage group, uint256 index)
        internal
        view
        returns (uint32)
    {
        return group._voters[index];
    }

    function amtOfVoter(Group storage group, uint32 acct)
        internal
        view
        returns (uint256)
    {
        return group._amtOfVoter[acct];
    }

    function sumOfAmt(Group storage group) internal view returns (uint256) {
        return group._sumOfAmt;
    }

    function voters(Group storage group) internal view returns (uint32[]) {
        return group._voters;
    }
}
