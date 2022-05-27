/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library SignerGroup {
    using ArrayUtils for uint32[];

    struct Group {
        mapping(uint32 => bytes32) _sigHash;
        mapping(uint32 => uint32) _sigDate;
        mapping(uint32 => uint16) _counterOfSigner;
        uint16 _counter;
        uint32[] _signers;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addSignature(
        Group storage group,
        uint32 acct,
        uint32 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        // require(sigDate > 0, "zero sigDate");

        if (group._sigDate[acct] == 0) {
            group._signers.push(acct);
            flag = true;
        }

        group._counterOfSigner[acct]++;
        group._counter++;

        group._sigDate[acct] = sigDate;
        group._sigHash[acct] = sigHash;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isSigner(Group storage group, uint32 acct)
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
        require(group._sigDate[acct] > 0, "not a signer");

        return group._sigDate[acct];
    }

    function sigHash(Group storage group, uint32 acct)
        internal
        view
        returns (bytes32)
    {
        require(group._sigDate[acct] > 0, "not a signer");

        return group._sigHash[acct];
    }

    function sigVerify(
        Group storage group,
        uint32 acct,
        string src
    ) internal view returns (bool) {
        require(group._sigDate[acct] > 0, "not a signer");

        return group._sigHash[acct] == keccak256(bytes(src));
    }

    function counterOfSigner(Group storage group, uint32 acct)
        internal
        view
        returns (uint16)
    {
        return group._counterOfSigner[acct];
    }

    function counterOfSigners(Group storage group)
        internal
        view
        returns (uint16)
    {
        return group._counter;
    }

    function qtyOfSigners(Group storage group) internal view returns (uint256) {
        return group._signers.length;
    }

    function getSigner(Group storage group, uint256 index)
        internal
        view
        returns (uint32)
    {
        return group._signers[index];
    }

    function signers(Group storage group) internal view returns (uint32[]) {
        return group._signers;
    }
}
