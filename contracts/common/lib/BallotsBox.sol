// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumsRepo.sol";
import "./EnumerableSet.sol";

library BallotsBox {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Ballot {
        uint40 voter;
        uint64 weight;
        uint8 attitude;
        uint32 blockNumber;
        uint32 sigDate;
        bytes32 sigHash;
    }

    struct Box {
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

    // #################
    // ##    Write    ##
    // #################

    function castVote(
        Box storage box,
        uint40 acct,
        uint8 attitude,
        uint64 weight,
        bytes32 sigHash
    ) internal returns (bool flag) {

        if (box.ballots[acct].sigDate == 0) {

            box.ballots[acct] = Ballot({
                voter: acct,
                weight: weight,
                attitude: attitude,
                blockNumber: uint32(block.number),
                sigDate: uint32(block.timestamp),
                sigHash: sigHash
            });

            box.sumOfWeight += weight;

            box.voters.push(acct);

            if (attitude == uint8(EnumsRepo.AttitudeOfVote.Support)) {
                box.supportVoters.add(acct);
                box.sumOfYea += weight;
            } else if (attitude == uint8(EnumsRepo.AttitudeOfVote.Against)) {
                box.againstVoters.add(acct);
                box.sumOfNay += weight;
            } else if (attitude == uint8(EnumsRepo.AttitudeOfVote.Abstain)) {
                box.abstainVoters.add(acct);
                box.sumOfAbs += weight;
            } else revert("BB.add: attitude overflow");

            flag = true;
        }
    }

    // #################
    // ##    Read     ##
    // #################

    function votedYea(Box storage box, uint40 acct)
        internal
        view
        returns (bool)
    {
        return box.supportVoters.contains(acct);
    }

    function votedNay(Box storage box, uint40 acct)
        internal
        view
        returns (bool)
    {
        return box.againstVoters.contains(acct);
    }

    function votedAbs(Box storage box, uint40 acct)
        internal
        view
        returns (bool)
    {
        return box.abstainVoters.contains(acct);
    }

    function getYea(Box storage box)
        internal
        view
        returns (uint40[] memory members, uint64 weights)
    {
        members = box.supportVoters.valuesToUint40();
        weights = box.sumOfYea;
    }

    function qtyOfYea(Box storage box)
        internal
        view
        returns (uint)
    {
        return box.supportVoters.length();
    }

    function getNay(Box storage box)
        internal
        view
        returns (uint40[] memory members, uint64 weights)
    {
        members = box.againstVoters.valuesToUint40();
        weights = box.sumOfNay;
    }

    function qtyOfNay(Box storage box)
        internal
        view
        returns (uint)
    {
        return box.againstVoters.length();
    }

    function getAbs(Box storage box)
        internal
        view
        returns (uint40[] memory members, uint64 weight)
    {
        members = box.abstainVoters.valuesToUint40();
        weight = box.sumOfAbs;
    }

    function qtyOfAbs(Box storage box)
        internal
        view
        returns (uint)
    {
        return box.abstainVoters.length();
    }

    function allVoters(Box storage box)
        internal
        view
        returns (uint40[] memory)
    {
        return box.voters;
    }

    function qtyOfAllVoters(Box storage box)
        internal
        view
        returns (uint)
    {
        return box.voters.length;
    }

    function isVoted(Box storage box, uint40 acct)
        internal
        view
        returns (bool)
    {
        return box.ballots[acct].sigDate > 0;
    }

    function getVote(Box storage box, uint40 acct)
        internal
        view
        returns (Ballot memory)
    {
        return box.ballots[acct];
    }
}
