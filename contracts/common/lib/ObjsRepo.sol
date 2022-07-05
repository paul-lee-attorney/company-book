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
        }

        return false;
    }

    function pickout(SeqList storage list, bytes32 value)
        internal
        returns (bool)
    {
        uint256 i = list.bytes32Set._inner._indexes[value];
        uint256 len = list.bytes32Set.length();

        while (len > i + 1) {
            list.bytes32Set._inner._values[i] = list.bytes32Set._inner._values[
                i + 1
            ];
            list.bytes32Set._inner._indexes[
                list.bytes32Set._inner._values[i]
            ]--;
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

    // ======== SignerGroup ========

    struct Signature {
        uint16 dealSN;
        uint32 blockNumber;
        uint32 sigDate;
        bytes32 sigHash;
    }

    struct SignerGroup {
        // acct => sigSN => sig
        mapping(uint256 => mapping(uint256 => Signature)) signatures;
        // acct => dealSN => sigSN
        mapping(uint256 => mapping(uint256 => uint256)) dealToSN;
        mapping(uint256 => uint256) counterOfSig;
        mapping(uint256 => uint256) counterOfBlank;
        uint256 balance;
        EnumerableSet.UintSet parties;
    }

    function addBlank(
        SignerGroup storage group,
        uint256 acct,
        uint256 snOfDeal
    ) internal returns (bool flag) {
        if (group.dealToSN[acct][snOfDeal] == 0) {
            group.parties.add(acct);

            group.counterOfBlank[acct]++;
            uint256 sn = group.counterOfBlank[acct];

            group.dealToSN[acct][snOfDeal] = sn;
            group.signatures[acct][sn].dealSN = uint16(snOfDeal);

            group.balance++;

            flag = true;
        }
    }

    function removeParty(SignerGroup storage group, uint256 acct)
        internal
        returns (bool flag)
    {
        uint256 len = group.counterOfBlank[acct];

        if (len > 0 && group.counterOfSig[acct] == 0) {
            group.balance -= len;

            while (len > 0) {
                uint256 snOfDeal = uint256(
                    group.signatures[acct][len - 1].dealSN
                );
                delete group.dealToSN[acct][snOfDeal];
                delete group.signatures[acct][len - 1];
                len--;
            }

            delete group.counterOfBlank[acct];

            group.parties.remove(acct);

            flag = true;
        }
    }

    function signDeal(
        SignerGroup storage group,
        uint40 acct,
        uint16 snOfDeal,
        bytes32 sigHash
    ) internal returns (bool flag) {
        uint256 sn = group.dealToSN[acct][snOfDeal];

        if (sn > 0 && group.signatures[acct][sn].sigDate == 0) {
            Signature storage sig = group.signatures[acct][sn];

            sig.blockNumber = uint32(block.number);
            sig.sigDate = uint32(block.timestamp);
            sig.sigHash = sigHash;

            if (snOfDeal == 0) {
                Signature storage docSig = group.signatures[acct][0];
                docSig.blockNumber = uint32(block.number);
                docSig.sigDate = uint32(block.timestamp);
                docSig.sigHash = sigHash;
            }

            group.counterOfSig[acct]++;
            group.balance--;

            flag = true;
        }
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
        EnumerableSet.UintSet supportVoters;
        uint256 sumOfYea;
        EnumerableSet.UintSet againstVoters;
        uint256 sumOfNay;
        EnumerableSet.UintSet abstainVoters;
        uint256 sumOfAbs;
        mapping(uint256 => Ballot) ballots;
        uint256 sumOfWeight;
        uint256[] voters;
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
        returns (uint40[] membersOfYea, uint256 supportVotes)
    {
        membersOfYea = box.supportVoters.valuesToUint40();
        supportVotes = box.sumOfYea;
    }

    function getNay(BallotsBox storage box)
        internal
        view
        returns (uint40[] membersOfNay, uint256 againstVotes)
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
        mapping(uint8 => uint256) startDateOf;
        uint8 currentState;
    }

    function setState(TimeLine storage line, uint8 state) internal {
        line.currentState = state;
        line.startDateOf[state] = block.number;
    }

    function pushToNextState(TimeLine storage line) internal {
        line.currentState++;
        line.startDateOf[line.currentState] = block.number;
    }

    function backToPrevState(TimeLine storage line) internal {
        require(line.currentState > 0, "currentState overflow");
        line.startDateOf[line.currentState] = 0;
        line.currentState--;
    }

    // ======== ArrayUtils ========
    function fullyCoveredBy(uint40[] arrA, uint40[] arrB)
        internal
        pure
        returns (bool)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        bool flag;

        for (uint256 i = 0; i < lenA; i++) {
            flag = false;
            for (uint256 j = 0; j < lenB; j++) {
                if (arrB[j] == arrA[i]) {
                    flag = true;
                    break;
                }
            }
            if (!flag) return false;
        }

        return true;
    }
}
