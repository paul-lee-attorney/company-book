/**
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 ***/

pragma solidity ^0.4.24;

import "./EnumsRepo.sol";
import "./EnumerableSet.sol";
import "./SNParser.sol";

library ObjsRepo {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    // using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    //======== SNList ========

    struct SNList {
        mapping(bytes6 => bytes32) shortToSN;
        EnumerableSet.Bytes32Set bytes32Set;
    }

    function add(SNList storage list, bytes32 value) internal returns (bool) {
        if (list.bytes32Set.add(value)) {
            list.shortToSN[value.short()] = value;
            return true;
        }

        return false;
    }

    function remove(SNList storage list, bytes32 value)
        internal
        returns (bool)
    {
        if (list.bytes32Set.remove(value)) {
            delete list.shortToSN[value.short()];
            return true;
        }

        return false;
    }

    function contains(SNList storage list, bytes6 ssn)
        internal
        view
        returns (bool)
    {
        bytes32 value = list.shortToSN[ssn];
        return list.bytes32Set.contains(value);
    }

    function length(SNList storage list) internal view returns (uint256) {
        return list.bytes32Set.length();
    }

    function at(SNList storage list, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return list.bytes32Set.at(index);
    }

    function values(SNList storage list)
        internal
        view
        returns (bytes32[] memory)
    {
        return list.bytes32Set.values();
    }

    //======== SeqList ========

    struct SeqList {
        mapping(uint16 => bytes32) seqToSN;
        EnumerableSet.Bytes32Set bytes32Set;
    }

    function add(SeqList storage list, bytes32 value) internal returns (bool) {
        if (list.bytes32Set.add(value)) {
            list.seqToSN[value.sequence()] = value;
            return true;
        }

        return false;
    }

    function append(
        SeqList storage list,
        bytes32 value,
        uint256 bit
    ) internal returns (bool) {
        uint256 len = list.bytes32Set.length();

        if (!add(list, value)) return false;

        while (len > 0) {
            if (
                uint256(list.bytes32Set._inner._values[len - 1] << bit) <=
                uint256(list.bytes32Set._inner._values[len] << bit)
            ) break;

            (
                list.bytes32Set._inner._values[len - 1],
                list.bytes32Set._inner._values[len]
            ) = (
                list.bytes32Set._inner._values[len],
                list.bytes32Set._inner._values[len - 1]
            );

            list.bytes32Set._inner._indexes[
                list.bytes32Set._inner._values[len - 1]
            ] = len - 1;

            list.bytes32Set._inner._indexes[
                list.bytes32Set._inner._values[len]
            ] = len;

            len--;
        }

        return true;
    }

    function remove(SeqList storage list, bytes32 value)
        internal
        returns (bool)
    {
        if (list.bytes32Set.remove(value)) {
            delete list.seqToSN[value.sequence()];
            return true;
        } else {
            return false;
        }
    }

    function pickout(SeqList storage list, bytes32 value)
        internal
        returns (bool)
    {
        uint256 i = list.bytes32Set._inner._indexes[value];
        uint256 len = list.bytes32Set.length();

        while (i < len - 1) {
            list.bytes32Set._inner._values[i] = list.bytes32Set._inner._values[
                i + 1
            ];
            list.bytes32Set._inner._indexes[
                list.bytes32Set._inner._values[i]
            ] = i;
            i++;
        }

        delete list.bytes32Set._inner._values[len - 1];
        list.bytes32Set._inner._values.length--;

        delete list.bytes32Set._inner._indexes[value];

        delete list.seqToSN[value.sequence()];

        return true;
    }

    function getSN(SeqList storage list, uint16 ssn)
        internal
        view
        returns (bytes32)
    {
        return list.seqToSN[ssn];
    }

    function contains(SeqList storage list, uint16 ssn)
        internal
        view
        returns (bool)
    {
        bytes32 value = list.seqToSN[ssn];
        return list.bytes32Set.contains(value);
    }

    function length(SeqList storage list) internal view returns (uint256) {
        return list.bytes32Set.length();
    }

    function at(SeqList storage list, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return list.bytes32Set.at(index);
    }

    function values(SeqList storage list)
        internal
        view
        returns (bytes32[] memory)
    {
        return list.bytes32Set.values();
    }

    // ======== BallotsBox ========

    struct Ballot {
        uint40 voter;
        uint64 weight;
        uint8 attitude;
        uint32 blockNumber;
        uint32 sigDate;
        bytes32 sigHash;
    }

    struct BallotsBox {
        uint64 sumOfWeight;
        uint64 sumOfYea;
        uint64 sumOfNay;
        uint64 sumOfAbs;
        EnumerableSet.UintSet supportVoters;
        EnumerableSet.UintSet againstVoters;
        EnumerableSet.UintSet abstainVoters;
        mapping(uint256 => Ballot) ballots;
        uint40[] voters;
    }

    function add(
        BallotsBox storage box,
        uint40 acct,
        uint8 attitude,
        uint64 voteAmt,
        bytes32 sigHash
    ) internal returns (bool flag) {
        if (box.ballots[acct].sigDate == 0) {
            Ballot storage ballot = box.ballots[acct];

            ballot.voter = acct;
            ballot.weight = voteAmt;
            ballot.attitude = attitude;
            ballot.blockNumber = uint32(block.number);
            ballot.sigDate = uint32(block.timestamp);
            ballot.sigHash = sigHash;

            box.sumOfWeight += voteAmt;

            box.voters.push(acct);

            if (attitude == uint8(EnumsRepo.AttitudeOfVote.Support)) {
                box.supportVoters.add(acct);
                box.sumOfYea += voteAmt;
            } else if (attitude == uint8(EnumsRepo.AttitudeOfVote.Against)) {
                box.againstVoters.add(acct);
                box.sumOfNay += voteAmt;
            } else if (attitude == uint8(EnumsRepo.AttitudeOfVote.Abstain)) {
                box.abstainVoters.add(acct);
                box.sumOfAbs += voteAmt;
            } else revert("attitude overflow");

            flag = true;
        }
    }

    function votedYea(BallotsBox storage box, uint40 acct)
        internal
        view
        returns (bool flag)
    {
        return box.supportVoters.contains(acct);
    }

    function votedNay(BallotsBox storage box, uint40 acct)
        internal
        view
        returns (bool flag)
    {
        return box.againstVoters.contains(acct);
    }

    function getYea(BallotsBox storage box)
        internal
        view
        returns (uint40[] membersOfYea, uint64 supportVotes)
    {
        membersOfYea = box.supportVoters.valuesToUint40();
        supportVotes = box.sumOfYea;
    }

    function getNay(BallotsBox storage box)
        internal
        view
        returns (uint40[] membersOfNay, uint64 againstVotes)
    {
        membersOfNay = box.againstVoters.valuesToUint40();
        againstVotes = box.sumOfNay;
    }

    function isVoted(BallotsBox storage box, uint40 acct)
        internal
        view
        returns (bool)
    {
        return box.ballots[acct].sigDate > 0;
    }

    function getVote(BallotsBox storage box, uint40 acct)
        internal
        view
        returns (
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        )
    {
        Ballot storage ballot = box.ballots[acct];

        weight = ballot.weight;
        attitude = ballot.attitude;
        blockNumber = ballot.blockNumber;
        sigDate = ballot.sigDate;
        sigHash = ballot.sigHash;
    }

    // ======== TimeLine ========

    struct TimeLine {
        mapping(uint8 => uint32) startDateOf;
        uint8 currentState;
    }

    function setState(TimeLine storage line, uint8 state) internal {
        line.currentState = state;
        line.startDateOf[state] = uint32(block.timestamp);
    }

    function pushToNextState(TimeLine storage line) internal {
        line.currentState++;
        line.startDateOf[line.currentState] = uint32(block.timestamp);
    }

    function backToPrevState(TimeLine storage line) internal {
        require(line.currentState > 0, "currentState overflow");
        line.startDateOf[line.currentState] = 0;
        line.currentState--;
    }

    // ======== MarkChain ========

    struct Mark {
        uint40 key;
        uint64 value;
        uint40 prev;
        uint40 next;
    }

    struct MarkChain {
        uint40 head;
        uint40 tail;
        mapping(uint256 => Mark) marks;
    }

    function addMark(
        MarkChain storage c,
        uint40 key,
        uint64 value
    ) internal returns (bool) {
        if (c.marks[key].key == 0) {
            Mark storage m = c.marks[key];

            m.key = key;
            m.value = value;

            _insertToChain(c, key);

            return true;
        }
        return false;
    }

    function _insertToChain(MarkChain storage c, uint40 key) private {
        Mark storage m = c.marks[key];

        uint40 cur = c.tail;

        if (cur == 0) {
            c.head = key;
            c.tail = key;
        } else {
            while (cur > 0) {
                if (c.marks[cur].value <= m.value) break;
                else cur = c.marks[cur].prev;
            }

            if (cur > 0) {
                m.next = c.marks[cur].next;
                if (m.next > 0) c.marks[m.next].prev = key;
                c.marks[cur].next = key;
                m.prev = cur;
            } else {
                m.next = c.head;
                c.marks[c.head].prev = key;
                c.head = key;
            }
        }
    }

    function updateMark(
        MarkChain storage c,
        uint40 key,
        uint64 value
    ) internal returns (bool) {
        Mark storage m = c.marks[key];

        if (key > 0 && m.key == key) {
            m.value = value;
            _unlinkMark(c, key);
            _insertToChain(c, key);
            return true;
        } else {
            return false;
        }
    }

    function _unlinkMark(MarkChain storage c, uint40 key) private {
        Mark storage m = c.marks[key];

        if (key != c.tail) c.marks[m.next].prev = m.prev;
        else c.tail = m.prev;

        if (key != c.head) c.marks[m.prev].next = m.next;
        else c.head = m.next;
    }

    function removeMark(MarkChain storage c, uint40 key)
        internal
        returns (bool)
    {
        Mark storage m = c.marks[key];

        if (key > 0 && m.key == key) {
            _unlinkMark(c, key);
            delete c.marks[key];
            return true;
        } else {
            return false;
        }
    }

    function contains(MarkChain storage c, uint40 key)
        internal
        view
        returns (bool flag)
    {
        if (key > 0 && c.marks[key].key == key) flag = true;
    }

    function markedValue(MarkChain storage c, uint40 key)
        internal
        view
        returns (uint64 value)
    {
        if (contains(c, key)) value = c.marks[key].value;
    }

    function topValue(MarkChain storage c) internal view returns (uint64) {
        return c.marks[c.tail].value;
    }

    function topKey(MarkChain storage c) internal view returns (uint40) {
        return c.tail;
    }

    function prevKey(MarkChain storage c, uint40 cur)
        internal
        view
        returns (uint40)
    {
        return c.marks[cur].prev;
    }

    function nextKey(MarkChain storage c, uint40 cur)
        internal
        view
        returns (uint40)
    {
        return c.marks[cur].next;
    }

    // ==== FRDeals ====

    struct Record {
        uint16 ssn; // FR sequence number
        uint64 weight; // FR rightholder's voting weight
        uint16 ratio;
    }

    struct FRDeals {
        uint16 counterOfFR;
        uint64 sumOfWeight;
        // sequence => Record
        mapping(uint16 => Record) records;
    }

    function execFirstRefusalRight(
        FRDeals storage self,
        uint16 ssnOfFR,
        uint64 weight
    ) internal returns (uint16) {
        self.counterOfFR++;
        self.sumOfWeight += weight;

        Record storage record = self.records[self.counterOfFR];
        record.ssn = ssnOfFR;
        record.weight = weight;

        return self.counterOfFR;
    }

    function getRatioOfFRs(FRDeals storage self) internal {
        uint16 len = self.counterOfFR;
        while (len > 0) {
            self.records[len].ratio = uint16(
                (self.records[len].weight * 10000) / self.sumOfWeight
            );
            len--;
        }
    }

    function getDeals(FRDeals storage self) internal view returns (uint16[]) {
        uint16 len = self.counterOfFR;
        require(len > 0, "zero length of FRDeals");
        uint16[] memory output = new uint16[](len);

        while (len > 0) {
            output[len - 1] = self.records[len].ssn;
            len--;
        }

        return output;
    }
}
