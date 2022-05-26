/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./UserGroup.sol";

library SigList {
    using UserGroup for UserGroup.Group;

    struct List {
        mapping(uint32 => bytes32) _sigHash;
        mapping(uint32 => uint32) _sigDate;
        UserGroup.Group _sigParties;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addSignature(
        List storage list,
        uint32 party,
        uint32 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        list._sigHash[party] = sigHash;
        list._sigDate[party] = sigDate;
        flag = list._sigParties.addMember(party);
    }

    // function removeSignature(List storage list, uint32 party)
    //     internal
    //     returns (bool flag)
    // {
    //     if (list._sigParties.removeMember(party)) {
    //         list._sigDate[party] = 0;
    //         list._sigHash[party] = bytes32(0);
    //         flag = true;
    //     }
    // }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isSigner(List storage list, uint32 acct)
        internal
        view
        returns (bool)
    {
        return list._sigParties.isMember(acct);
    }

    function sigDate(List storage list, uint32 acct)
        internal
        view
        returns (uint32)
    {
        require(isSigner(list, acct), "not a signer");

        return list._sigDate[acct];
    }

    function sigHash(List storage list, uint32 acct)
        internal
        view
        returns (bytes32)
    {
        require(isSigner(list, acct), "not a signer");

        return list._sigHash[acct];
    }

    function sigVerify(
        List storage list,
        uint32 acct,
        string src
    ) internal view returns (bool) {
        require(isSigner(list, acct), "not a signer");

        return list._sigHash[acct] == keccak256(bytes(src));
    }

    function counterOfSigner(List storage list, uint32 acct)
        internal
        view
        returns (uint16)
    {
        return list._sigParties.counterOfMember(acct);
    }

    function counterOfSigners(List storage list)
        internal
        view
        returns (uint16)
    {
        return list._sigParties.counterOfMembers();
    }

    function qtyOfSigners(List storage list) internal view returns (uint256) {
        return list._sigParties.qtyOfMembers();
    }

    function signers(List storage list) internal view returns (uint32[]) {
        return list._sigParties.members();
    }
}
