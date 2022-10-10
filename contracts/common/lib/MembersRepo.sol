// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// pragma experimental ABIEncoderV2;

import "./TopChain.sol";
import "./Checkpoints.sol";
import "./EnumerableSet.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using TopChain for TopChain.Chain;

    struct Member {
        Checkpoints.History votesInHand;
        EnumerableSet.Bytes32Set sharesInHand;
    }

    /*
        members[0] {
            votesInHand: ownersEquity;
            sharesInHand: sharesList;
        }
    */

    /* Node[0] {
        acct: (counterOfShares);
        group: counterOfGroups;
        deep: (maxQtyOfMembers);
        prev: tail;
        next: head;
        up: qtyOfMembers;
        down: (counterOfClasses);
        amt: lenOfChain;
        sum: totalVotes;
    } */

    struct GeneralMeeting {
        TopChain.Chain chain;
        mapping(uint256 => Member) members;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== restore mapping ====

    function restoreChain(
        GeneralMeeting storage gm,
        TopChain.Node[] memory snapshot
    ) internal {
        gm.chain.restoreChain(snapshot);
    }

    // ==== Zero Node Setting ====

    function increaseCounterOfShares(GeneralMeeting storage gm) internal {
        gm.chain.increaseZeroAcct();
    }

    function setMaxQtyOfMembers(GeneralMeeting storage gm, uint8 max) internal {
        gm.chain.setZeroDeep(max);
    }

    function increaseCounterOfClasses(GeneralMeeting storage gm) internal {
        gm.chain.increaseZeroDown();
    }

    function setAmtBase(GeneralMeeting storage gm, bool _basedOnPar) internal returns (bool flag) {
        
        if ((parCap(gm) == gm.chain.totalVotes()) != _basedOnPar) {

            uint40 i = 0;

            uint40 cur = gm.chain.head();

            while (i < qtyOfMembers(gm)) {

                (uint64 paid, uint64 par) = gm.members[cur].votesInHand.latest();

                if (paid != par) {
                    if (_basedOnPar) gm.chain.changeAmt(cur, (par - paid), false);
                    else gm.chain.changeAmt(cur, (par - paid), true);
                }

                cur = gm.chain.nextNode(cur);

                i++;

            }
            flag = true;
        }
    }

    // ==== Member ====

    function addMember(GeneralMeeting storage gm, uint40 acct)
        internal
        returns (bool flag)
    {
        flag = gm.chain.addNode(acct);
    }

    function delMember(GeneralMeeting storage gm, uint40 acct)
        internal
        returns (bool flag)
    {
        if (gm.chain.delNode(acct)) {

            delete gm.members[acct];

            flag = true;
        }
    }

    function addShareToMember(
        GeneralMeeting storage gm,
        bytes32 shareNumber,
        uint40 acct
    ) internal returns (bool flag) {
        if (gm.members[0].sharesInHand.add(shareNumber)) {
            flag = gm.members[acct].sharesInHand.add(shareNumber);
        }
    }

    function removeShareFromMember(
        GeneralMeeting storage gm,
        bytes32 shareNumber,
        uint40 acct
    ) internal returns (bool flag) {
        if (gm.members[0].sharesInHand.remove(shareNumber)) {
            flag = gm.members[acct].sharesInHand.remove(shareNumber);
        }
    }

    function addMemberToGroup(
        GeneralMeeting storage gm,
        uint40 acct,
        uint16 group
    ) internal {
        uint40 _counterOfGroups = gm.chain.counterOfGroups();

        require(
            group > 0 && group <= _counterOfGroups + 1,
            "MC.addMemberToGroup: group overflow"
        );

        TopChain.Node storage n = gm.chain.nodes[acct];

        uint40 top = gm.chain.leaderOfGroup(group);

        if (top > 0) {
            (uint40 up, uint40 down) = gm.chain.getVPos(n.amt, 0, top, true);

            gm.chain.vInsert(acct, up, down);
        } else {
            if (group > _counterOfGroups) {
                gm.chain.increaseCounterOfGroups();
            } else revert("SHR.addMemberToGroup: groupNo has been revoked");

            n.group = group;

            (uint40 prev, uint40 next) = gm.chain.getHPos(
                n.amt,
                0,
                gm.chain.head(),
                true
            );
            gm.chain.hInsert(acct, prev, next);
        }
    }

    function removeMemberFromChain(GeneralMeeting storage gm, uint40 acct)
        internal
        returns(bool flag)
    {
        flag = gm.chain.hCarveOut(acct);
    }

    function removeMemberFromGroup(GeneralMeeting storage gm, uint40 acct)
        internal
        returns (bool flag)
    {
        flag = gm.chain.vCarveOut(acct);
    }

    function changeAmtOfMember(
        GeneralMeeting storage gm,
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) internal returns (uint64 blocknumber) {
        uint64 deltaAmt = (basedOnPar(gm)) ? deltaPar : deltaPaid;
        gm.chain.changeAmt(acct, deltaAmt, decrease);

        (uint64 paid, uint64 par) = gm.members[acct].votesInHand.latest();

        if (decrease) {
            paid -= deltaPaid;
            par -= deltaPar;
        } else {
            paid += deltaPaid;
            par += deltaPar;
        }

        blocknumber = gm.members[acct].votesInHand.push(paid, par);
    }

    function changeAmtOfCap(
        GeneralMeeting storage gm,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) internal returns (uint64 blocknumber) {
        (uint64 paid, uint64 par) = gm.members[0].votesInHand.latest();

        if (decrease) {
            paid -= deltaPaid;
            par -= deltaPar;
        } else {
            paid += deltaPaid;
            par += deltaPar;
        }

        blocknumber = gm.members[0].votesInHand.push(paid, par);
    }

    // ==== Zero Node Setting ====
    function init(GeneralMeeting storage gm, uint8 max) internal {
        gm.chain.init();
        setMaxQtyOfMembers(gm, max);
    }

    function addCounterOfShares(GeneralMeeting storage gm) internal {
        gm.chain.increaseZeroAcct();
    }

    function addCounterOfClass(GeneralMeeting storage gm) internal {
        gm.chain.increaseZeroDown();
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Zero Node ====

    function counterOfShares(GeneralMeeting storage gm)
        internal
        view
        returns (uint32)
    {
        return uint32(gm.chain.zeroAcct());
    }

    function counterOfGroups(GeneralMeeting storage gm)
        internal
        view
        returns (uint16)
    {
        return gm.chain.counterOfGroups();
    }

    function maxQtyOfMembers(GeneralMeeting storage gm)
        internal
        view
        returns (uint8)
    {
        return gm.chain.zeroDeep();
    }

    function tailOfChain(GeneralMeeting storage gm)
        internal
        view
        returns (uint16)
    {
        return gm.chain.tail();
    }

    function controllor(GeneralMeeting storage gm)
        internal
        view
        returns (uint16)
    {
        return gm.chain.head();
    }

    function qtyOfGroups(GeneralMeeting storage gm)
        internal
        view
        returns (uint16)
    {
        return gm.chain.lenOfChain();
    }

    function counterOfClasses(GeneralMeeting storage gm)
        internal
        view
        returns (uint16)
    {
        return gm.chain.zeroDown();
    }

    function totalVotes(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        return gm.chain.totalVotes();
    }

    function basedOnPar(GeneralMeeting storage gm) internal view returns(bool) {
        (, uint64 par) = gm.members[0].votesInHand.latest();
        return par == gm.chain.totalVotes();
    }

    // ==== shares ====

    function sharesList(GeneralMeeting storage gm)
        internal
        view
        returns (bytes32[] memory)
    {
        return gm.members[0].sharesInHand.values();
    }

    function sharenumberExist(GeneralMeeting storage gm, bytes32 sharenumber)
        internal
        view
        returns (bool)
    {
        return gm.members[0].sharesInHand.contains(sharenumber);
    }

    // ==== members ====

    function isMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (bool)
    {
        return gm.members[acct].node > 0;
    }

    function qtyOfMembers(GeneralMeeting storage gm)
        internal
        view
        returns (uint40 qty)
    {
        qty = gm.chain.qtyOfMembers();
    }

    function membersList(GeneralMeeting storage gm)
        internal
        view
        returns (uint40[] memory)
    {
        return gm.chain.membersList();
    }

    // ==== member ====

    function indexOfMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint16)
    {
        return gm.members[acct].node;
    }

    function paidOfMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64 paid)
    {
        (paid, ) = gm.members[acct].votesInHand.latest();
    }

    function parOfMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64 par)
    {
        (, par) = gm.members[acct].votesInHand.latest();
    }

    function votesInHand(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64)
    {
        uint256 i = indexOfMember(gm, acct);
        return gm.chain.nodes[i].amt;
    }

    function votesAtBlock(
        GeneralMeeting storage gm,
        uint40 acct,
        uint64 blocknumber,
        bool voteBasedOnPar
    ) internal view returns (uint64 vote) {
        if (voteBasedOnPar)
            (, vote) = gm.members[acct].votesInHand.getAtBlock(blocknumber);
        else (vote, ) = gm.members[acct].votesInHand.getAtBlock(blocknumber);
    }

    function sharesInHand(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (bytes32[] memory)
    {
        return gm.members[acct].sharesInHand.values();
    }

    function qtyOfSharesInHand(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint256)
    {
        return gm.members[acct].sharesInHand.length();
    }

    // ==== group ====

    function groupNo(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint16)
    {
        uint16 i = indexOfMember(gm, acct);
        return gm.chain.groupNo(i);
    }

    function votesOfHead(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        uint16 head = controllor(gm);
        return gm.chain.nodes[head].sum;
    }

    function isGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (bool)
    {
        return gm.chain.leaderIndexOfGroup(group) > 0;
    }

    function leaderOfGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (uint40)
    {
        return gm.chain.leaderOfGroup(group);
    }

    function votesOfGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (uint64)
    {
        return gm.chain.votesOfGroup(group);
    }

    function membersOfGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (uint40[] memory)
    {
        return gm.chain.membersOfGroup(group);
    }

    function affiliated(
        GeneralMeeting storage gm,
        uint40 acct1,
        uint40 acct2
    ) internal view returns (bool) {
        return
            gm.chain.affiliated(gm.members[acct1].node, gm.members[acct2].node);
    }

    function deepOfGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (uint16)
    {
        uint16 top = gm.chain.leaderIndexOfGroup(group);

        if (top > 0) {
            return gm.chain.deepOfBranch(top);
        } else {
            return 0;
        }
    }

    function paidCap(GeneralMeeting storage gm)
        internal
        view
        returns (uint64 paid)
    {
        (paid, ) = gm.members[0].votesInHand.latest();
    }

    function parCap(GeneralMeeting storage gm)
        internal
        view
        returns (uint64 par)
    {
        (, par) = gm.members[0].votesInHand.latest();
    }

    function capAtBlock(GeneralMeeting storage gm, uint64 blocknumber)
        internal
        view
        returns (uint64 paid, uint64 par)
    {
        (paid, par) = gm.members[0].votesInHand.getAtBlock(blocknumber);
    }

    function getSnapshot(GeneralMeeting storage gm)
        internal
        view
        returns (TopChain.Node[] memory)
    {
        return gm.chain.getSnapshot();
    }
}
