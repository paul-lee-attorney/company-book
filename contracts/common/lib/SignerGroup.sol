/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./PartyGroup.sol";

library SignerGroup {
    using PartyGroup for PartyGroup.Group;

    struct Group {
        mapping(uint32 => bytes32) _sigHash;
        mapping(uint32 => uint32) _sigDate;
        PartyGroup.Group _signers;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addSignature(
        Group storage group,
        uint32 party,
        uint32 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        group._sigHash[party] = sigHash;
        group._sigDate[party] = sigDate;
        flag = group._signers.addParty(party);
    }

    // function removeSignature(Group storage group, uint32 party)
    //     internal
    //     returns (bool flag)
    // {
    //     if (group._signers.removeMember(party)) {
    //         group._sigDate[party] = 0;
    //         group._sigHash[party] = bytes32(0);
    //         flag = true;
    //     }
    // }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isSigner(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group._signers.isParty(acct);
    }

    function sigDate(Group storage group, uint32 acct)
        internal
        view
        returns (uint32)
    {
        require(group._signers.isParty(acct), "not a signer");

        return group._sigDate[acct];
    }

    function sigHash(Group storage group, uint32 acct)
        internal
        view
        returns (bytes32)
    {
        require(group._signers.isParty(acct), "not a signer");

        return group._sigHash[acct];
    }

    function sigVerify(
        Group storage group,
        uint32 acct,
        string src
    ) internal view returns (bool) {
        require(group._signers.isParty(acct), "not a signer");

        return group._sigHash[acct] == keccak256(bytes(src));
    }

    function counterOfSigner(Group storage group, uint32 acct)
        internal
        view
        returns (uint16)
    {
        return group._signers.counterOfParty(acct);
    }

    function counterOfSigners(Group storage group)
        internal
        view
        returns (uint16)
    {
        return group._signers.counterOfParties();
    }

    function qtyOfSigners(Group storage group) internal view returns (uint256) {
        return group._signers.qtyOfParties();
    }

    function getSigner(Group storage group, uint256 index)
        internal
        view
        returns (uint32)
    {
        return group._signers.getParty(index);
    }

    function signers(Group storage group) internal view returns (uint32[]) {
        return group._signers.parties();
    }
}
