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
        acct: counterOfShares;
        group: counterOfGroups;
        deep: maxQtyOfMembers;
        prev: tail;
        next: head;
        up: qtyOfMembers;
        down: counterOfClasses;
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
        gm.chain.increaseCounterOfShares();
    }

    function setMaxQtyOfMembers(GeneralMeeting storage gm, uint16 max) internal {
        gm.chain.setMaxQtyOfMembers(max);
    }

    function increaseCounterOfClasses(GeneralMeeting storage gm) internal {
        gm.chain.increaseCounterOfClasses();
    }

    function setAmtBase(GeneralMeeting storage gm, bool _basedOnPar) internal returns (bool flag) {
        
        if (basedOnPar(gm) != _basedOnPar) {

            uint40 cur = gm.chain.head();

            while (cur > 0) {

                (uint64 paid, uint64 par) = gm.members[cur].votesInHand.latest();

                if (paid != par) {
                    if (_basedOnPar) gm.chain.changeAmt(cur, (par - paid), false);
                    else gm.chain.changeAmt(cur, (par - paid), true);
                }

                cur = gm.chain.nextNode(cur);
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
        if (addShareNumberToList(gm, shareNumber)) {
            flag = gm.members[acct].sharesInHand.add(shareNumber);
        }
    }

    function removeShareFromMember(
        GeneralMeeting storage gm,
        bytes32 shareNumber,
        uint40 acct
    ) internal returns (bool flag) {
        if (removeShareNumberFromList(gm, shareNumber)) {
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

            if (prev != n.prev && next != n.next) gm.chain.hInsert(acct, prev, next);
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
        (uint64 paid, uint64 par) = ownersEquity(gm);

        if (decrease) {
            paid -= deltaPaid;
            par -= deltaPar;
        } else {
            paid += deltaPaid;
            par += deltaPar;
        }

        blocknumber = updateOwnersEquity(gm, paid, par);
    }

    // ==== Zero Node Setting ====

    function addShareNumberToList(GeneralMeeting storage gm, bytes32 shareNumber) internal returns (bool flag) {
        flag = gm.members[0].sharesInHand.add(shareNumber);
    }

    function removeShareNumberFromList(GeneralMeeting storage gm, bytes32 shareNumber) internal returns (bool flag) {
        flag = gm.members[0].sharesInHand.remove(shareNumber);
    }

    function addCounterOfShares(GeneralMeeting storage gm) internal {
        gm.chain.increaseCounterOfShares();
    }

    function addCounterOfGroups(GeneralMeeting storage gm) internal {
        gm.chain.increaseCounterOfGroups();
    }

    function addCounterOfClasses(GeneralMeeting storage gm) internal {
        gm.chain.increaseCounterOfClasses();
    }

    function updateOwnersEquity(GeneralMeeting storage gm, uint64 paid, uint64 par) internal returns(uint64 blocknumber) {
        blocknumber = gm.members[0].votesInHand.push(paid, par);
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
        return gm.chain.counterOfShares();
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
        returns (uint16)
    {
        return gm.chain.maxQtyOfMembers();
    }

    function tailOfChain(GeneralMeeting storage gm)
        internal
        view
        returns (uint40)
    {
        return gm.chain.tail();
    }

    function controllor(GeneralMeeting storage gm)
        internal
        view
        returns (uint40)
    {
        return gm.chain.head();
    }

    function qtyOfGroups(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        return gm.chain.lenOfChain();
    }

    function counterOfClasses(GeneralMeeting storage gm)
        internal
        view
        returns (uint16)
    {
        return gm.chain.counterOfClasses();
    }

    function totalVotes(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        return gm.chain.totalVotes();
    }

    function basedOnPar(GeneralMeeting storage gm) internal view returns(bool) {
        return parCap(gm) == totalVotes(gm);
    }

    // ==== shares ====

    function sharesList(GeneralMeeting storage gm)
        internal
        view
        returns (bytes32[] memory)
    {
        return gm.members[0].sharesInHand.values();
    }

    function shareNumberExist(GeneralMeeting storage gm, bytes32 sharenumber)
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
        return gm.chain.isMember(acct);
    }

    function qtyOfMembers(GeneralMeeting storage gm)
        internal
        view
        returns (uint16 qty)
    {
        qty = uint16(gm.chain.qtyOfMembers());
    }

    function membersList(GeneralMeeting storage gm)
        internal
        view
        returns (uint40[] memory)
    {
        return gm.chain.membersList();
    }

    // ==== member ====

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
        returns (uint64 votes)
    {
        if(isMember(gm, acct))
        votes = gm.chain.nodes[acct].amt;
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
        return gm.chain.groupNo(acct);
    }

    function votesOfHead(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        uint40 head = controllor(gm);
        return gm.chain.nodes[head].sum;
    }

    function isGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (bool)
    {
        return gm.chain.leaderOfGroup(group) > 0;
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
        return gm.chain.affiliated(acct1, acct2);
    }

    function deepOfGroup(GeneralMeeting storage gm, uint16 group)
        internal
        view
        returns (uint16)
    {
        uint40 top = gm.chain.leaderOfGroup(group);

        if (top > 0) {
            return gm.chain.deepOfBranch(top);
        } else {
            return 0;
        }
    }

    function ownersEquity(GeneralMeeting storage gm) internal view returns(uint64 paid, uint64 par) {
        (paid, par) = gm.members[0].votesInHand.latest();
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
