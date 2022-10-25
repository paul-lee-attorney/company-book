// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./SNParser.sol";
import "./EnumsRepo.sol";
import "./EnumerableSet.sol";
import "./BallotsBox.sol";
import "./DelegateMap.sol";

import "../components/ISigPage.sol";

import "../../books/bos/IBookOfShares.sol";
import "../../books/boh/IShareholdersAgreement.sol";

library MotionsRepo {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;

    struct Head {
        uint8 typeOfMotion;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(not to buy) 4-rejected (to buy)        
        uint40 submitter;
        uint40 executor;
        uint32 proposeBN;
        uint32 weightRegBN;
        uint32 voteStartBN;
        uint32 voteEndBN;
    }

    struct Motion {
        Head head;
        bytes32 votingRule;
        BallotsBox.Box box;
        DelegateMap.Map map;
    }

    struct Repo {
        mapping(uint256 => Motion) motions;
        EnumerableSet.UintSet motionIds;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== delegate ====

    function entrustDelegate(
        Repo storage repo,
        uint40 acct,
        uint40 delegate,
        uint256 motionId
    ) internal returns(bool flag) {
        if (!repo.motions[motionId].box.isVoted(acct)) {
            flag = repo.motions[motionId].map.entrustDelegate(acct, delegate);
        }
    }

    // ==== propose ====

    function proposeMotion(
        Repo storage repo,
        uint256 motionId,
        bytes32 rule,
        Head memory head
    ) internal returns (bool flag) {
        if (!isProposed(repo, motionId)) {
            Motion storage m = repo.motions[motionId];

            m.votingRule = rule;
            m.head = head;
            m.head.state = uint8(EnumsRepo.StateOfMotion.Proposed);

            repo.motionIds.add(motionId);
            
            flag = true;
        }
    }

    // ==== vote ====

    function castVote(
        Repo storage repo,
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash,
        uint64 weight
    ) internal returns(bool flag) 
    {
        if (onVoting(repo, motionId) && !repo.motions[motionId].map.isPrincipal(caller)) {
            flag = repo.motions[motionId].box.castVote(caller, attitude, weight, sigHash);
        }
    }

    // ==== counting ====

    function voteCounting(Repo storage repo, uint256 motionId, IBookOfShares _bos) 
        internal 
        returns(bool flag) 
    {
        if (afterVoteEnd(repo, motionId)) {

            (
                uint64 totalHead,
                uint64 totalAmt,
                uint64 consentHead,
                uint64 consentAmt
            ) = _getParas(repo, motionId, _bos);

            bool flag1;
            bool flag2;

            Motion storage motion = repo.motions[motionId];

            uint40 vetoHolder = motion.votingRule.vetoHolderOfVR();

            if (vetoHolder == 0 || motion.box.votedYea(vetoHolder)) {
                flag1 = motion.votingRule.ratioHeadOfVR() > 0
                    ? totalHead > 0
                        ? ((motion.box.qtyOfYea() + consentHead) *
                            10000) / totalHead >=
                            motion.votingRule.ratioHeadOfVR()
                        : false
                    : true;

                flag2 = motion.votingRule.ratioAmountOfVR() > 0
                    ? totalAmt > 0
                        ? ((motion.box.sumOfYea + consentAmt) * 
                            10000) / totalAmt >=
                            motion.votingRule.ratioAmountOfVR()
                        : false
                    : true;
            }

            motion.head.state = flag1 && flag2
                ? uint8(EnumsRepo.StateOfMotion.Passed)
                : motion.votingRule.againstShallBuyOfVR()
                    ? uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy)
                    : uint8(EnumsRepo.StateOfMotion.Rejected_NotToBuy);

            flag = true;
        }
    }

    function _getParas(Repo storage repo, uint256 motionId, IBookOfShares _bos)
        private
        view
        returns (
            uint64 totalHead,
            uint64 totalAmt,
            uint64 consentHead,
            uint64 consentAmt
        )
    {
        Motion storage motion = repo.motions[motionId];

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = uint64(motion.box.qtyOfAllVoters());
            totalAmt = motion.box.sumOfWeight;
        } else {
            // members hold voting rights at block
            totalHead = _bos.qtyOfMembers();
            totalAmt = _bos.votesAtBlock(0, motion.head.weightRegBN);

            if (motion.head.typeOfMotion < 8) {
                // 1-7 typeOfIA; 8-external deal

                // minus parties of IA;
                uint40[] memory parties = ISigPage(address(uint160(motionId))).parties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint64 voteAmt = _bos.votesAtBlock(
                        parties[len - 1],
                        motion.head.weightRegBN
                    );

                    // party has voting right at block
                    if (voteAmt > 0) {
                        if (motion.votingRule.partyAsConsentOfVR()) {
                            consentHead++;
                            consentAmt += voteAmt;
                        } else {
                            totalHead--;
                            totalAmt -= voteAmt;
                        }
                    }

                    len--;
                }
            }

            // members not cast vote
            if (motion.votingRule.impliedConsentOfVR()) {
                consentHead += (totalHead - uint64(motion.box.voters.length));
                consentAmt += (totalAmt - motion.box.sumOfWeight);
            }
        }
    }

    //##################
    //##    Read     ##
    //################

    function beforeVoteStart(Repo storage repo, uint256 motionId) internal view returns(bool) {
        return repo.motions[motionId].head.voteStartBN > block.number;
    }

    function afterVoteEnd(Repo storage repo, uint256 motionId) internal view returns(bool) {
        return repo.motions[motionId].head.voteEndBN < block.number;
    }

    function onVoting(Repo storage repo, uint256 motionId) internal view returns(bool) {
        return repo.motions[motionId].head.voteStartBN <= block.number &&
            block.number <= repo.motions[motionId].head.voteEndBN;
    }

    function isProposed(Repo storage repo, uint256 motionId) internal view returns(bool) {
        return repo.motionIds.contains(motionId);
    }

    function headOf(Repo storage repo, uint256 motionId)
        internal
        view
        returns (Head memory)
    {
        return repo.motions[motionId].head;
    }

    function votingRule(Repo storage repo, uint256 motionId)
        internal
        view
        returns (bytes32)
    {
        return repo.motions[motionId].votingRule;
    }

    function state(Repo storage repo, uint256 motionId)
        internal
        view
        returns (uint8)
    {
        return repo.motions[motionId].head.state;
    }

    function isPassed(Repo storage repo, uint256 motionId)
        internal
        view
        returns (bool)
    {
        return
            repo.motions[motionId].head.state == uint8(EnumsRepo.StateOfMotion.Passed);
    }

    function isExecuted(Repo storage repo, uint256 motionId)
        internal
        view
        returns (bool)
    {
        return
            repo.motions[motionId].head.state == uint8(EnumsRepo.StateOfMotion.Executed);
    }

    function isRejected(Repo storage repo, uint256 motionId)
        internal
        view
        returns (bool)
    {
        return (repo.motions[motionId].head.state == uint8(EnumsRepo.StateOfMotion.Rejected_NotToBuy) ||
            repo.motions[motionId].head.state == uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy));
    }
}
