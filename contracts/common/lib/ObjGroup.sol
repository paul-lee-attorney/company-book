/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";
import "./SNParser.sol";

library ObjGroup {
    using ArrayUtils for uint8[];
    using ArrayUtils for uint16[];
    using ArrayUtils for uint40[];
    using ArrayUtils for bytes32[];
    using ArrayUtils for address[];

    using SNParser for bytes32;

    // ======== SNList ========

    struct SNList {
        mapping(bytes6 => bool) isItem;
        bytes32[] items;
    }

    function addItem(SNList storage list, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (!list.isItem[sn.short()]) {
            list.isItem[sn.short()] = true;
            sn.insertToQue(list.items);
            flag = true;
        }
    }

    function removeItem(SNList storage list, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (list.isItem[sn.short()]) {
            list.isItem[sn.short()] = false;
            list.items.removeByValue(sn);
            flag = true;
        }
    }

    // ======== EnumList ========

    struct EnumList {
        mapping(uint8 => bool) isItem;
        uint8[] items;
    }

    function addItem(EnumList storage list, uint8 title)
        internal
        returns (bool flag)
    {
        if (!list.isItem[title]) {
            list.isItem[title] = true;
            list.items.push(title);
            flag = true;
        }
    }

    function removeItem(EnumList storage list, uint8 title)
        internal
        returns (bool flag)
    {
        if (list.isItem[title]) {
            list.isItem[title] = false;
            list.items.removeByValue(title);
            flag = true;
        }
    }

    // ======== SeqList ========

    struct SeqList {
        mapping(uint16 => bool) isItem;
        uint16[] items;
    }

    function addItem(SeqList storage list, uint16 seqNo)
        internal
        returns (bool flag)
    {
        if (!list.isItem[seqNo]) {
            list.isItem[seqNo] = true;
            list.items.push(seqNo);
            flag = true;
        }
    }

    function removeItem(SeqList storage list, uint16 seqNo)
        internal
        returns (bool flag)
    {
        if (list.isItem[seqNo]) {
            list.isItem[seqNo] = false;
            list.items.removeByValue(seqNo);
            flag = true;
        }
    }

    // ======== AddrList ========

    struct AddrList {
        mapping(address => bool) isItem;
        address[] items;
    }

    function addItem(AddrList storage list, address addr)
        internal
        returns (bool flag)
    {
        if (!list.isItem[addr]) {
            list.isItem[addr] = true;
            list.items.push(addr);
            flag = true;
        }
    }

    function removeItem(AddrList storage list, address addr)
        internal
        returns (bool flag)
    {
        if (list.isItem[addr]) {
            list.isItem[addr] = false;
            list.items.removeByValue(addr);
            flag = true;
        }
    }

    // ======== UserGroup ========

    struct UserGroup {
        mapping(uint40 => bool) isMember;
        uint40[] members;
    }

    function addMember(UserGroup storage group, uint40 acct)
        internal
        returns (bool flag)
    {
        if (!group.isMember[acct]) {
            group.isMember[acct] = true;
            group.members.push(acct);
            flag = true;
        }
    }

    function removeMember(UserGroup storage group, uint40 acct)
        internal
        returns (bool flag)
    {
        if (group.isMember[acct]) {
            group.isMember[acct] = false;
            group.members.removeByValue(acct);
            flag = true;
        }
    }

    // ======== SignerGroup ========

    struct SignerGroup {
        mapping(uint40 => mapping(uint16 => uint16)) dealToSN;
        mapping(uint40 => mapping(uint16 => bytes32)) sigHash;
        mapping(uint40 => mapping(uint16 => uint32)) sigDate;
        mapping(uint40 => uint16) counterOfSig;
        mapping(uint40 => uint16) counterOfBlank;
        uint16 balance;
        uint40[] parties;
    }

    function addBlank(
        SignerGroup storage group,
        uint40 acct,
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

    function removeParty(SignerGroup storage group, uint40 acct)
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
        SignerGroup storage group,
        uint40 acct,
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

    // ======== VoterGroup ========

    struct VoterGroup {
        mapping(uint40 => uint32) sigDate;
        mapping(uint40 => bytes32) sigHash;
        mapping(uint40 => uint256) amtOfVoter;
        uint256 sumOfAmt;
        uint40[] voters;
    }

    function addVote(
        VoterGroup storage group,
        uint40 acct,
        uint256 amount,
        uint32 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        if (group.sigDate[acct] == 0) {
            group.sigDate[acct] = sigDate;
            group.sigHash[acct] = sigHash;
            group.amtOfVoter[acct] = amount;
            group.sumOfAmt += amount;
            group.voters.push(acct);
            flag = true;
        }
    }

    // ======== TimeLine ========

    struct TimeLine {
        mapping(uint8 => uint32) startDateOf;
        uint8 currentState;
    }

    function setState(
        TimeLine storage line,
        uint8 state,
        uint32 startDate
    ) internal {
        line.currentState = state;
        line.startDateOf[state] = startDate;
    }

    function pushToNextState(TimeLine storage line, uint32 nextKeyDate)
        internal
    {
        line.currentState++;
        line.startDateOf[line.currentState] = nextKeyDate;
    }

    function backToPrevState(TimeLine storage line) internal {
        require(line.currentState > 0, "currentState overflow");
        line.startDateOf[line.currentState] = 0;
        line.currentState--;
    }
}
