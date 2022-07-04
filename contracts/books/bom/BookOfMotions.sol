/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../boa/IInvestmentAgreement.sol";

import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BODSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "../../common/components/ISigPage.sol";

import "./IBookOfMotions.sol";

contract BookOfMotions is
    IBookOfMotions,
    SHASetting,
    BOASetting,
    BOSSetting,
    BODSetting
{
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.BallotsBox;

    struct Motion {
        bytes32 sn;
        bytes32 votingRule;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(not to buy) 4-rejected (to buy)
        ObjsRepo.BallotsBox box;
    }

    // motionId => delegateNo => memberNo
    mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet))
        private _delegates;

    // motionId => authorizers
    mapping(uint256 => EnumerableSet.UintSet) private _authorizers;

    // motionId => Motion
    mapping(uint256 => Motion) private _motions;

    EnumerableSet.UintSet private _motionIds;

    //####################
    //##    modifier    ##
    //####################

    modifier onlyProposed(uint256 motionId) {
        require(_motionIds.contains(motionId), "motion is NOT proposed");
        _;
    }

    modifier beforeExpire(uint256 motionId) {
        require(
            _motions[motionId].sn.votingDeadlineOfMotion() >= block.number,
            "missed voting deadline"
        );
        _;
    }

    modifier afterExpire(uint256 motionId) {
        require(
            _motions[motionId].sn.votingDeadlineOfMotion() < block.number,
            "still on voting"
        );
        _;
    }

    modifier notVotedTo(uint256 motionId, uint40 caller) {
        require(!isVoted(motionId, caller), "HAVE voted for the motion");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 typeOfMotion,
        uint40 submitter,
        uint32 proposeDate,
        uint32 votingDeadlineBN,
        uint32 weightRegBlock
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfMotion);
        _sn = _sn.acctToSN(1, submitter);
        _sn = _sn.dateToSN(6, proposeDate);
        _sn = _sn.dateToSN(10, votingDeadlineBN);
        _sn = _sn.dateToSN(14, weightRegBlock);

        sn = _sn.bytesToBytes32();
    }

    function _createNomination(
        uint8 typeOfMotion,
        uint40 nominator,
        uint32 proposeDate,
        uint32 votingDeadlineBN,
        uint32 weightRegBlock,
        uint40 candidate
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfMotion);
        _sn = _sn.acctToSN(1, nominator);
        _sn = _sn.dateToSN(6, proposeDate);
        _sn = _sn.dateToSN(10, votingDeadlineBN);
        _sn = _sn.dateToSN(14, weightRegBlock);

        _sn = _sn.acctToSN(18, candidate);

        sn = _sn.bytesToBytes32();
    }

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyDirectKeeper
    {
        bytes32 rule = _getSHA().votingRules(
            uint8(EnumsRepo.TypeOfVoting.ElectDirector)
        );

        // uint8 title = uint8(EnumsRepo.TitleOfDirectors.Director);

        bytes32 sn = _createNomination(
            uint8(EnumsRepo.TypeOfVoting.ElectDirector),
            nominator,
            uint32(block.number),
            uint32(block.number) +
                (uint32(rule.votingDaysOfVR()) * 24 * _rc.blocksPerHour()),
            uint32(block.number),
            candidate
        );

        uint256 motionId = uint256(sn);

        require(!_motionIds.contains(motionId), "the motion has been proposed");

        Motion storage motion = _motions[motionId];

        motion.votingRule = rule;
        motion.sn = sn;
        motion.state = uint8(EnumsRepo.StateOfMotion.Proposed);

        _motionIds.add(motionId);

        emit ProposeMotion(
            motionId,
            uint8(EnumsRepo.TypeOfVoting.ElectDirector),
            new address[](1),
            new bytes[](1),
            bytes32(0),
            motion.sn
        );
    }

    function proposeMotion(address ia, uint40 submitter)
        external
        onlyDirectKeeper
    {
        require(ISigPage(ia).established(), "doc is not established");

        uint256 motionId = uint256(ia);

        require(!_motionIds.contains(motionId), "the motion has been proposed");

        uint8 typeOfMotion = _boa.typeOfIA(ia);

        bytes32 rule = _getSHA().votingRules(typeOfMotion);

        Motion storage motion = _motions[motionId];

        motion.votingRule = rule;
        motion.sn = _createSN(
            typeOfMotion,
            submitter,
            uint32(block.timestamp),
            _boa.votingDeadlineBNOf(ia),
            _boa.reviewDeadlineBNOf(ia)
        );
        motion.state = uint8(EnumsRepo.StateOfMotion.Proposed);

        _motionIds.add(motionId);

        emit ProposeMotion(
            uint256(ia),
            typeOfMotion,
            new address[](1),
            new bytes[](1),
            bytes32(0),
            motion.sn
        );
    }

    function authorizeToPropose(
        uint40 rightholder,
        uint40 delegate,
        uint256 actionId
    ) external onlyDirectKeeper {
        require(_bos.isMember(rightholder), "authorizer is not a member");
        require(_bos.isMember(delegate), "delegate is not a member");

        require(
            _motions[actionId].state == uint8(EnumsRepo.StateOfMotion.Pending),
            "action has been proposed"
        );

        if (_authorizers[actionId].add(rightholder)) {
            _delegates[actionId][delegate].add(rightholder);
            emit AuthorizeToPropose(rightholder, delegate, actionId);
        }
    }

    function proposeAction(
        uint8 actionType,
        address[] target,
        bytes[] params,
        bytes32 desHash,
        uint40 submitter
    ) external onlyDirectKeeper {
        uint256 actionId = _hashAction(actionType, target, params, desHash);
        require(!_motionIds.contains(actionId), "motion has been proposed");
        require(
            _proposalWeight(actionId, submitter) >=
                _getSHA().proposalThreshold(),
            "insufficient voting weight"
        );

        bytes32 rule = _getSHA().votingRules(actionType);

        Motion storage motion = _motions[actionId];

        motion.votingRule = rule;
        motion.sn = _createSN(
            actionType,
            submitter,
            uint32(block.timestamp),
            uint32(block.number) +
                (uint32(rule.votingDaysOfVR()) * 24 * _rc.blocksPerHour()),
            uint32(block.number)
        );
        motion.state = uint8(EnumsRepo.StateOfMotion.Proposed);

        _motionIds.add(actionId);

        emit ProposeMotion(
            actionId,
            actionType,
            target,
            params,
            desHash,
            motion.sn
        );
    }

    function _proposalWeight(uint256 actionId, uint40 acct)
        private
        view
        returns (uint256)
    {
        uint256 len = _delegates[actionId][acct].length();
        uint256 weight;

        while (len > 0) {
            uint40 shareholder = uint40(_delegates[actionId][acct].at(len - 1));
            weight += _bos.voteInHand(shareholder);
            len--;
        }

        return (weight * 10000) / _bos.totalVote();
    }

    function _hashAction(
        uint8 actionType,
        address[] target,
        bytes[] params,
        bytes32 desHash
    ) private pure returns (uint256) {
        return
            uint256(keccak256(abi.encode(actionType, target, params, desHash)));
    }

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        notVotedTo(motionId, caller)
        beforeExpire(motionId)
    {
        Motion storage motion = _motions[motionId];

        uint32 regBlock = motion.sn.weightRegBlockOfMotion();
        uint64 voteAmt = uint64(_bos.votesAtBlock(caller, regBlock));

        if (motion.box.add(caller, attitude, voteAmt, sigHash)) {
            emit Vote(motionId, caller, attitude, voteAmt);
        }
    }

    function _getParas(uint256 motionId)
        private
        view
        returns (
            uint256 totalHead,
            uint256 totalAmt,
            uint256 consentHead,
            uint256 consentAmt
        )
    {
        Motion storage motion = _motions[motionId];

        uint32 regBlock = motion.sn.weightRegBlockOfMotion();

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = motion.box.voters.length;
            totalAmt = motion.box.sumOfWeight;
        } else {
            // members hold voting rights at block
            totalHead = _bos.qtyOfMembersAtBlock(regBlock);
            totalAmt = _bos.totalVoteAtBlock(regBlock);

            if (motion.sn.typeOfMotion() < 8) {
                // 1-7 typeOfIA; 8-external deal

                // minus parties of IA;
                uint40[] memory parties = ISigPage(address(uint160(motionId)))
                    .parties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint256 voteAmt = _bos.votesAtBlock(
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
                consentHead += (totalHead - motion.box.voters.length);
                consentAmt += (totalAmt - motion.box.sumOfWeight);
            }
        }
    }

    function voteCounting(uint256 motionId)
        external
        onlyDirectKeeper
        onlyProposed(motionId)
        afterExpire(motionId)
    {
        Motion storage motion = _motions[motionId];

        (
            uint256 totalHead,
            uint256 totalAmt,
            uint256 consentHead,
            uint256 consentAmt
        ) = _getParas(motionId);

        bool flag1 = motion.votingRule.ratioHeadOfVR() > 0
            ? totalHead > 0
                ? ((motion.box.supportVoters.length() + consentHead) * 10000) /
                    totalHead >=
                    motion.votingRule.ratioHeadOfVR()
                : false
            : true;

        bool flag2 = motion.votingRule.ratioAmountOfVR() > 0
            ? totalAmt > 0
                ? ((motion.box.sumOfYea + consentAmt) * 10000) / totalAmt >=
                    motion.votingRule.ratioAmountOfVR()
                : false
            : true;

        motion.state = flag1 && flag2
            ? uint8(EnumsRepo.StateOfMotion.Passed)
            : motion.votingRule.againstShallBuyOfVR()
            ? uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy)
            : uint8(EnumsRepo.StateOfMotion.Rejected_NotToBuy);

        emit VoteCounting(motionId, motion.state);
    }

    function _ratioOfNay(uint256 motionId, uint40 againstVoter)
        private
        view
        returns (uint256)
    {
        Motion storage motion = _motions[motionId];

        // require(
        //     motion.state == uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy),
        //     "agianst NO need to buy"
        // );
        require(motion.box.votedNay(againstVoter), "NOT NAY voter");

        return ((motion.box.ballots[againstVoter].weight * 10000) /
            motion.box.sumOfNay);
    }

    function execAction(
        uint8 actionType,
        address[] targets,
        bytes[] params,
        bytes32 desHash
    ) external onlyDirectKeeper returns (uint256) {
        uint256 actionId = _hashAction(actionType, targets, params, desHash);

        require(_motionIds.contains(actionId), "motion not proposed");

        Motion storage motion = _motions[actionId];

        require(
            motion.state == uint8(EnumsRepo.StateOfMotion.Passed),
            "voting NOT end"
        );

        motion.state = uint8(EnumsRepo.StateOfMotion.Executed);
        if (_execute(targets, params)) emit ExecuteAction(actionId, true);
        else emit ExecuteAction(actionId, false);

        return actionId;
    }

    function _execute(address[] memory targets, bytes[] memory params)
        internal
        returns (bool)
    {
        bool success;

        for (uint256 i = 0; i < targets.length; ++i) {
            success = targets[i].call(params[i]);
            if (!success) return success;
        }

        return success;
    }

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        onlyDirectKeeper
        returns (uint256 parValue, uint256 paidPar)
    {
        // uint256 ratio = _ratioOfNay(ia, againstVoter);

        require(
            block.number <
                IInvestmentAgreement(ia).closingDate(sn.sequenceOfDeal()),
            "MISSED closing date"
        );

        require(
            block.number <
                _motions[uint256(ia)].sn.votingDeadlineOfMotion() +
                    uint32(
                        _motions[uint256(ia)].votingRule.execDaysForPutOptOfVR()
                    ) *
                    24 *
                    _rc.blocksPerHour(),
            "MISSED execute deadline"
        );

        (, parValue, paidPar, , ) = IInvestmentAgreement(ia).getDeal(
            sn.sequenceOfDeal()
        );
    }

    //##################
    //##    读接口    ##
    //##################

    function votingRule(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        onlyUser
        returns (bytes32)
    {
        return _motions[motionId].votingRule;
    }

    function state(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        onlyUser
        returns (uint8)
    {
        return _motions[motionId].state;
    }

    function votedYea(uint256 motionId, uint40 acct)
        external
        view
        onlyUser
        returns (bool)
    {
        return _motions[motionId].box.votedYea(acct);
    }

    function votedNay(uint256 motionId, uint40 acct)
        external
        view
        onlyUser
        returns (bool)
    {
        return _motions[motionId].box.votedNay(acct);
    }

    function getYea(uint256 motionId)
        external
        view
        onlyUser
        returns (uint40[], uint256)
    {
        return _motions[motionId].box.getYea();
    }

    function getNay(uint256 motionId)
        external
        view
        onlyUser
        returns (uint40[], uint256)
    {
        return _motions[motionId].box.getNay();
    }

    function sumOfVoteAmt(uint256 motionId)
        external
        view
        onlyUser
        returns (uint256)
    {
        return _motions[motionId].box.sumOfWeight;
    }

    function isVoted(uint256 motionId, uint40 acct)
        public
        view
        onlyUser
        returns (bool)
    {
        return _motions[motionId].box.isVoted(acct);
    }

    function getVote(uint256 motionId, uint40 acct)
        external
        view
        onlyUser
        returns (
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        )
    {
        require(isVoted(motionId, acct), "did NOT vote");

        return _motions[motionId].box.getVote(acct);
    }

    function isPassed(uint256 motionId)
        external
        view
        onlyUser
        onlyProposed(motionId)
        returns (bool)
    {
        return
            _motions[motionId].state == uint8(EnumsRepo.StateOfMotion.Passed);
    }

    function isRejected(uint256 motionId)
        external
        view
        onlyUser
        onlyProposed(motionId)
        returns (bool)
    {
        return _motions[motionId].state > uint8(EnumsRepo.StateOfMotion.Passed);
    }
}
