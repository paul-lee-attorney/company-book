/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "./IBookOfMotions.sol";

import "../boa/IInvestmentAgreement.sol";

// import "../../common/components/IDocumentsRepo.sol";
import "../../common/components/ISigPage.sol";
import "../../common/components/MotionsRepo.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

contract BookOfMotions is
    IBookOfMotions,
    BOASetting,
    SHASetting,
    BOSSetting,
    MotionsRepo
{
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    //##################
    //##    写接口    ##
    //##################

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyManager(1)
    {
        bytes32 rule = _getSHA().votingRules(
            uint8(EnumsRepo.TypeOfVoting.ElectDirector)
        );

        bytes32 sn = _createSN(
            uint8(EnumsRepo.TypeOfVoting.ElectDirector),
            nominator,
            uint32(block.number),
            uint32(block.number) +
                (uint32(rule.votingDaysOfVR()) * 24 * _rc.blocksPerHour()),
            uint32(block.number),
            candidate
        );

        uint256 motionId = uint256(sn);

        _proposeMotion(
            motionId,
            rule,
            sn,
            uint8(EnumsRepo.TypeOfVoting.ElectDirector),
            new address[](1),
            new bytes[](1),
            bytes32(0)
        );
    }

    function proposeMotion(address ia, uint40 submitter)
        external
        onlyManager(1)
    {
        require(ISigPage(ia).established(), "doc is not established");

        uint256 motionId = uint256(uint160(ia));

        uint8 motionType = _boa.typeOfIA(ia);

        bytes32 rule = _getSHA().votingRules(motionType);

        bytes32 sn = _createSN(
            motionType,
            submitter,
            uint32(block.number),
            _boa.votingDeadlineBNOf(ia),
            _boa.reviewDeadlineBNOf(ia),
            0
        );

        _proposeMotion(
            motionId,
            rule,
            sn,
            motionType,
            new address[](1),
            new bytes[](1),
            bytes32(0)
        );
    }

    function authorizeToPropose(
        uint40 authorizer,
        uint40 delegate,
        uint256 motionId
    ) external onlyManager(1) {
        require(_bos.isMember(authorizer), "authorizer is not a member");
        require(_bos.isMember(delegate), "delegate is not a member");

        _authorizeDelegate(authorizer, delegate, motionId);
    }

    // function proposeAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash,
    //     uint40 submitter
    // ) external onlyManager(1) {
    //     bytes[] memory paramsBytes = _toBytes(params);

    //     uint256 actionId = _hashAction(
    //         actionType,
    //         targets,
    //         paramsBytes,
    //         desHash
    //     );
    //     require(
    //         _proposalWeight(actionId, submitter) >=
    //             _getSHA().proposalThreshold(),
    //         "insufficient voting weight"
    //     );
    //     bytes32 rule = _getSHA().votingRules(actionType);

    //     bytes32 sn = _createSN(
    //         actionType,
    //         submitter,
    //         uint32(block.timestamp),
    //         uint32(block.number) +
    //             (uint32(rule.votingDaysOfVR()) * 24 * _rc.blocksPerHour()),
    //         uint32(block.number),
    //         0
    //     );

    //     _proposeMotion(
    //         actionId,
    //         rule,
    //         sn,
    //         actionType,
    //         targets,
    //         paramsBytes,
    //         desHash
    //     );
    // }

    function _proposalWeight(uint256 actionId, uint40 acct)
        private
        view
        returns (uint64)
    {
        uint256 len = _delegates[actionId][acct].length();
        uint64 weight;

        while (len > 0) {
            uint40 shareholder = uint40(_delegates[actionId][acct].at(len - 1));
            weight += _bos.votesInHand(shareholder);
            len--;
        }

        return (weight * 10000) / _bos.totalVotes();
    }

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    )
        external
        onlyManager(1)
        notVotedTo(motionId, caller)
        beforeExpire(motionId)
    {
        Motion storage motion = _motions[motionId];

        uint32 regBlock = motion.sn.proposeBNOfMotion();
        uint64 voteAmt = uint64(_bos.votesAtBlock(caller, regBlock));

        _castVote(motionId, attitude, caller, sigHash, voteAmt);
    }

    function voteCounting(uint256 motionId)
        external
        onlyManager(1)
        onlyProposed(motionId)
        afterExpire(motionId)
    {
        Motion storage motion = _motions[motionId];

        (
            uint64 totalHead,
            uint64 totalAmt,
            uint64 consentHead,
            uint64 consentAmt
        ) = _getParas(motionId);

        bool flag1;
        bool flag2;

        uint40 vetoHolder = motion.votingRule.vetoHolderOfVR();

        if (vetoHolder == 0 || motion.box.supportVoters.contains(vetoHolder)) {
            flag1 = motion.votingRule.ratioHeadOfVR() > 0
                ? totalHead > 0
                    ? ((motion.box.supportVoters.length() + consentHead) *
                        10000) /
                        totalHead >=
                        motion.votingRule.ratioHeadOfVR()
                    : false
                : true;

            flag2 = motion.votingRule.ratioAmountOfVR() > 0
                ? totalAmt > 0
                    ? ((motion.box.sumOfYea + consentAmt) * 10000) / totalAmt >=
                        motion.votingRule.ratioAmountOfVR()
                    : false
                : true;
        }

        motion.state = flag1 && flag2
            ? uint8(EnumsRepo.StateOfMotion.Passed)
            : motion.votingRule.againstShallBuyOfVR()
            ? uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy)
            : uint8(EnumsRepo.StateOfMotion.Rejected_NotToBuy);

        emit VoteCounting(motionId, motion.state);
    }

    function _getParas(uint256 motionId)
        private
        view
        returns (
            uint64 totalHead,
            uint64 totalAmt,
            uint64 consentHead,
            uint64 consentAmt
        )
    {
        Motion storage motion = _motions[motionId];

        uint32 regBlock = motion.sn.weightRegBNOfMotion();

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = uint64(motion.box.voters.length);
            totalAmt = motion.box.sumOfWeight;
        } else {
            // members hold voting rights at block
            totalHead = _bos.qtyOfMembers();
            totalAmt = _bos.totalVotes();

            if (motion.sn.typeOfMotion() < 8) {
                // 1-7 typeOfIA; 8-external deal

                // minus parties of IA;
                uint40[] memory parties = ISigPage(address(uint160(motionId)))
                    .parties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint64 voteAmt = _bos.votesAtBlock(
                        parties[len - 1],
                        regBlock
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

    function _ratioOfNay(uint256 motionId, uint40 againstVoter)
        private
        view
        returns (uint16)
    {
        Motion storage motion = _motions[motionId];

        require(motion.box.votedNay(againstVoter), "NOT NAY voter");

        return
            uint16(
                (motion.box.ballots[againstVoter].weight * 10000) /
                    motion.box.sumOfNay
            );
    }

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        onlyManager(1)
        returns (uint64 par, uint64 paid)
    {
        require(
            block.number < IInvestmentAgreement(ia).closingDate(sn.sequence()),
            "MISSED closing date"
        );

        require(
            block.number <
                _motions[uint256(ia)].sn.votingDeadlineBNOfMotion() +
                    uint32(
                        _motions[uint256(ia)].votingRule.execDaysForPutOptOfVR()
                    ) *
                    24 *
                    _rc.blocksPerHour(),
            "MISSED execute deadline"
        );

        (, paid, par,  , ) = IInvestmentAgreement(ia).getDeal(
            sn.sequence()
        );
    }
}
