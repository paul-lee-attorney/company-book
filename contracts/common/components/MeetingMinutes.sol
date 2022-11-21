// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/ruting/BOHSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/MotionsRepo.sol";
import "../../common/lib/DelegateMap.sol";
import "../../common/lib/BallotsBox.sol";

import "./IMeetingMinutes.sol";

contract MeetingMinutes is IMeetingMinutes, BOHSetting, ROMSetting {
    using SNParser for bytes32;
    using MotionsRepo for MotionsRepo.Repo;
    using DelegateMap for DelegateMap.Map;
    using BallotsBox for BallotsBox.Box;

    MotionsRepo.Repo internal _mm;

    //##################
    //##    Write     ##
    //##################

    // ==== delegate ====

    function entrustDelegate(
        uint40 authorizer,
        uint40 delegate,
        uint256 motionId
    ) external onlyDK {
        if (_mm.entrustDelegate(authorizer, delegate, motionId))
            emit EntrustDelegate(motionId, authorizer, delegate);
    }

    // ==== propose ====

    function _hashAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(actionType, targets, values, params, desHash)
                )
            );
    }

    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter
    ) external onlyDK {
        uint256 actionId = _hashAction(
            actionType,
            targets,
            values,
            params,
            desHash
        );

        require(
            _proposalWeight(actionId, submitter) >=
                _getSHA().proposalThreshold(),
            "insufficient voting weight"
        );

        bytes32 rule = _getSHA().votingRules(actionType);

        MotionsRepo.Head memory head = MotionsRepo.Head({
            typeOfMotion: actionType,
            state: 0,
            submitter: submitter,
            executor: 0,
            proposeBN: uint32(block.number),
            weightRegBN: uint32(block.number) +
                uint32(rule.reviewDaysOfVR()) *
                24 *
                _rc.blocksPerHour(),
            voteStartBN: uint32(block.number) +
                uint32(rule.reviewDaysOfVR()) *
                24 *
                _rc.blocksPerHour(),
            voteEndBN: uint32(block.number) +
                uint32(rule.votingDaysOfVR()) *
                24 *
                _rc.blocksPerHour()
        });

        if (_mm.proposeMotion(actionId, rule, head))
            emit ProposeAction(actionId, actionType, submitter);
    }

    function _proposalWeight(uint256 actionId, uint40 acct)
        private
        view
        returns (uint64)
    {
        uint40[] memory principals = _mm.motions[actionId].map.getPrincipals(
            acct
        );
        uint256 len = principals.length;
        uint64 weight = _rom.votesInHand(acct);

        while (len > 0) {
            weight += _rom.votesInHand(principals[len - 1]);
            len--;
        }

        return (weight * 10000) / _rom.totalVotes();
    }

    // ==== cast vote ====

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK {
        MotionsRepo.Head memory head = _mm.headOf(motionId);

        uint64 voteAmt;

        if (_mm.motions[motionId].map.isDelegate(caller))
            voteAmt = _voteWeight(motionId, caller, head.weightRegBN);
        else voteAmt = uint64(_rom.votesAtBlock(caller, head.weightRegBN));

        _mm.castVote(motionId, attitude, caller, sigHash, voteAmt);
    }

    function _voteWeight(
        uint256 motionId,
        uint40 acct,
        uint64 blocknumber
    ) private view returns (uint64) {
        uint40[] memory principals = _mm.motions[motionId].map.getPrincipals(
            acct
        );
        uint256 len = principals.length;
        uint64 weight = _rom.votesAtBlock(acct, blocknumber);

        while (len > 0) {
            weight += _rom.votesAtBlock(principals[len - 1], blocknumber);
            len--;
        }

        uint64 votes;

        if (_rom.basedOnPar()) (, votes) = _rom.capAtBlock(blocknumber);
        else (votes, ) = _rom.capAtBlock(blocknumber);

        return (weight * 10000) / votes;
    }

    // ==== counting ====

    function voteCounting(uint256 motionId) external onlyDK {
        if (
            _mm.state(motionId) == uint8(MotionsRepo.StateOfMotion.Proposed) &&
            _mm.voteCounting(motionId, _rom)
        ) emit VoteCounting(motionId, _mm.state(motionId));
    }

    // ==== execute ====

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external onlyDK returns (uint256) {
        uint256 motionId = _hashAction(
            actionType,
            targets,
            values,
            params,
            desHash
        );

        require(
            _mm.state(motionId) == uint8(MotionsRepo.StateOfMotion.Passed),
            "BOD.execAction: voting NOT end"
        );

        _mm.motions[motionId].head.state = uint8(
            MotionsRepo.StateOfMotion.Executed
        );

        if (_execute(targets, values, params))
            emit ExecuteAction(motionId, true);
        else emit ExecuteAction(motionId, false);

        return motionId;
    }

    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) private returns (bool success) {
        for (uint256 i = 0; i < targets.length; i++) {
            (success, ) = targets[i].call{value: values[i]}(params[i]);
            if (!success) return success;
        }
    }

    //##################
    //##    Read     ##
    //################

    // ==== delegate ====

    function isPrincipal(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].map.isPrincipal(acct);
    }

    function isDelegate(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].map.isDelegate(acct);
    }

    function delegateOf(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40)
    {
        return _mm.motions[motionId].map.getDelegate(acct);
    }

    function principalsOf(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40[] memory)
    {
        return _mm.motions[motionId].map.getPrincipals(acct);
    }

    // ==== motion ====

    function isProposed(uint256 motionId) external view returns (bool) {
        return _mm.isProposed(motionId);
    }

    function headOf(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory)
    {
        return _mm.headOf(motionId);
    }

    function votingRule(uint256 motionId) external view returns (bytes32) {
        return _mm.votingRule(motionId);
    }

    function state(uint256 motionId) external view returns (uint8) {
        return _mm.state(motionId);
    }

    // ==== voting ====

    function votedYea(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].box.votedYea(acct);
    }

    function votedNay(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].box.votedNay(acct);
    }

    function votedAbs(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].box.votedAbs(acct);
    }

    function getYea(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _mm.motions[motionId].box.getYea();
    }

    function qtyOfYea(uint256 motionId) external view returns (uint256) {
        return _mm.motions[motionId].box.qtyOfYea();
    }

    function getNay(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _mm.motions[motionId].box.getNay();
    }

    function qtyOfNay(uint256 motionId) external view returns (uint256) {
        return _mm.motions[motionId].box.qtyOfNay();
    }

    function getAbs(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _mm.motions[motionId].box.getAbs();
    }

    function qtyOfAbs(uint256 motionId) external view returns (uint256) {
        return _mm.motions[motionId].box.qtyOfAbs();
    }

    function allVoters(uint256 motionId)
        external
        view
        returns (uint40[] memory)
    {
        return _mm.motions[motionId].box.allVoters();
    }

    function qtyOfAllVoters(uint256 motionId) external view returns (uint256) {
        return _mm.motions[motionId].box.qtyOfAllVoters();
    }

    function sumOfVoteAmt(uint256 motionId) external view returns (uint64) {
        return _mm.motions[motionId].box.sumOfWeight;
    }

    function isVoted(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].box.isVoted(acct);
    }

    function getVote(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint40 voter,
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        )
    {
        return _mm.motions[motionId].box.getVote(acct);
    }

    function isPassed(uint256 motionId) external view returns (bool) {
        return _mm.isPassed(motionId);
    }

    function isExecuted(uint256 motionId) external view returns (bool) {
        return _mm.isExecuted(motionId);
    }

    function isRejected(uint256 motionId) external view returns (bool) {
        return _mm.isRejected(motionId);
    }
}
