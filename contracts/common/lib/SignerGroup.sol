/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library SignerGroup {
    using ArrayUtils for uint32[];

    struct Group {
        mapping(uint32 => mapping(uint16 => uint16)) dealToSN;
        mapping(uint32 => mapping(uint16 => bytes32)) sigHash;
        mapping(uint32 => mapping(uint16 => uint32)) sigDate;
        mapping(uint32 => uint16) counterOfSig;
        mapping(uint32 => uint16) counterOfBlank;
        uint16 balance;
        uint32[] parties;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addBlank(
        Group storage group,
        uint32 acct,
        uint16 snOfDeal
    ) internal returns (bool flag) {
        if (group.dealToSN[acct][snOfDeal] == 0) {
            if (group.counterOfBlank[acct] == 0) group.parties.push(acct);

            group.counterOfBlank[acct]++;
            group.dealToSN[acct][snOfDeal] = group.counterOfBlank[acct];

            group.balance++;

            flag = true;
        }
    }

    function removeParty(Group storage group, uint32 acct)
        internal
        returns (bool flag)
    {
        if (group.counterOfBlank[acct] > 0) {
            group.balance -= group.counterOfBlank[acct];

            for (uint16 i = 0; i <= group.counterOfBlank[acct]; i++) {
                delete group.sigDate[acct][i];
                delete group.sigHash[acct][i];
            }

            delete group.counterOfBlank[acct];
            delete group.counterOfSig[acct];

            group.parties.removeByValue(acct);

            flag = true;
        }
    }

    function signDeal(
        Group storage group,
        uint32 acct,
        uint16 snOfDeal,
        uint32 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        uint16 sn = group.dealToSN[acct][snOfDeal];

        if (sn > 0 && group.sigDate[acct][sn] == 0) {
            group.sigDate[acct][sn] = sigDate;
            group.sigHash[acct][sn] = sigHash;

            if (snOfDeal == 0) {
                group.sigDate[acct][0] = sigDate;
                group.sigHash[acct][0] = sigHash;
            }

            group.counterOfSig[acct]++;
            group.balance--;

            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isParty(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group.counterOfBlank[acct] > 0;
    }

    function isSigner(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group.counterOfSig[acct] > 0;
    }

    function isInitSigner(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group.sigDate[acct][0] > 0;
    }

    function sigDateOfDeal(
        Group storage group,
        uint32 acct,
        uint16 snOfDeal
    ) internal view returns (uint32) {
        uint16 sn = group.dealToSN[acct][snOfDeal];
        if (sn > 0) return group.sigDate[acct][sn];
        else revert("party did not sign this deal");
    }

    function sigHashOfDeal(
        Group storage group,
        uint32 acct,
        uint16 snOfDeal
    ) internal view returns (bytes32) {
        uint16 sn = group.dealToSN[acct][snOfDeal];
        if (sn > 0) return group.sigHash[acct][sn];
        else revert("party did not sign this deal");
    }

    function sigDateOfDoc(Group storage group, uint32 acct)
        internal
        view
        returns (uint32)
    {
        return group.sigDate[acct][0];
    }

    function sigHashOfDoc(Group storage group, uint32 acct)
        internal
        view
        returns (bytes32)
    {
        return group.sigHash[acct][0];
    }

    function dealSigVerify(
        Group storage group,
        uint32 acct,
        uint16 snOfDeal,
        string src
    ) internal view returns (bool) {
        uint16 sn = group.dealToSN[acct][snOfDeal];
        return group.sigHash[acct][sn] == keccak256(bytes(src));
    }

    function partyDulySigned(Group storage group, uint32 acct)
        internal
        view
        returns (bool)
    {
        return group.counterOfBlank[acct] == group.counterOfSig[acct];
    }

    function docEstablished(Group storage group) internal view returns (bool) {
        return group.balance == 0 && group.parties.length > 0;
    }
}
