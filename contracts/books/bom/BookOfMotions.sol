/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../boa/interfaces/IAgreement.sol";

import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/VoterGroup.sol";
import "../../common/lib/AddrGroup.sol";

import "../../common/components/interfaces/ISigPage.sol";

contract BookOfMotions is SHASetting, BOASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using VoterGroup for VoterGroup.Group;
    using AddrGroup for AddrGroup.Group;

    struct Motion {
        bytes32 sn;
        bytes32 votingRule;
        VoterGroup.Group supportVoters;
        VoterGroup.Group againstVoters;
        VoterGroup.Group allVoters;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(no need to buy) 4-rejected (against need to buy)
    }

    // ia/sha... => Motion
    mapping(address => Motion) private _motions;

    // Investment Agreements Subject to voting
    AddrGroup.Group private _ias;

    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(address indexed ia, bytes32 sn);

    event Vote(address indexed ia, uint32 voter, bool support, uint256 voteAmt);

    event TurnOverVote(address indexed ia, uint32 voter, uint256 voteAmt);

    event VoteCounting(address indexed ia, uint8 result);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyProposed(address ia) {
        require(_ias.isMember(ia), "IA is NOT isProposed");
        _;
    }

    modifier onlyOnVoting(address ia) {
        require(_motions[ia].state == 1, "Motion already voted");
        _;
    }

    modifier beforeExpire(address ia) {
        require(
            now - 15 minutes <= _motions[ia].sn.votingDeadlineOfMotion(),
            "missed voting deadline"
        );
        _;
    }

    modifier notVotedTo(address ia, uint32 caller) {
        require(
            !_motions[ia].allVoters.isVoter(caller),
            "HAVE voted for the IA"
        );
        _;
    }

    modifier onlyPartyOfIA(address ia, uint32 caller) {
        require(ISigPage(ia).isParty(caller), "NOT a Party to the IA");
        _;
    }

    modifier notPartyOfIA(address ia, uint32 caller) {
        require(!ISigPage(ia).isParty(caller), "Party shall AVOID");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        address ia,
        uint32 submitter,
        uint32 proposeDate,
        uint32 votingDeadline
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.dateToSN(0, submitter);
        _sn = _sn.dateToSN(4, proposeDate);
        _sn = _sn.dateToSN(8, votingDeadline);
        _sn = _sn.addrToSN(12, ia);

        sn = _sn.bytesToBytes32();
    }

    function proposeMotion(
        address ia,
        uint32 proposeDate,
        uint32 submitter
    ) external onlyDirectKeeper {
        require(
            _boa.passedReview(ia),
            "Agreement not passed review procesedure"
        );

        require(ISigPage(ia).established(), "Agreement not established");

        require(
            !_ias.isMember(ia),
            "the InvestmentAgreement has been proposed"
        );

        bytes32 rule = _getSHA().votingRules(_agrmtCal.typeOfIA(ia));

        uint32 votingDeadline = proposeDate +
            uint32(rule.votingDaysOfVR()) *
            86400;

        Motion storage motion = _motions[ia];

        motion.votingRule = rule;
        motion.sn = _createSN(ia, submitter, proposeDate, votingDeadline);
        motion.state = 1;

        if (_ias.addMember(ia)) emit ProposeMotion(ia, motion.sn);
    }

    function _getVoteAmount(address ia, uint32 caller)
        private
        view
        returns (uint256 amount)
    {
        if (_motions[ia].votingRule.basedOnParOfVR()) {
            amount = _bos.parInHand(caller);
        } else {
            amount = _bos.paidInHand(caller);
        }
    }

    function supportMotion(
        address ia,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        notVotedTo(ia, caller)
        onlyOnVoting(ia)
        beforeExpire(ia)
    {
        uint256 voteAmt = _getVoteAmount(ia, caller);

        Motion storage motion = _motions[ia];

        if (motion.allVoters.addVote(caller, voteAmt, sigDate, sigHash)) {
            motion.supportVoters.addVote(caller, voteAmt, sigDate, sigHash);
            emit Vote(ia, caller, true, voteAmt);
        }
    }

    function againstMotion(
        address ia,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        notVotedTo(ia, caller)
        onlyOnVoting(ia)
        beforeExpire(ia)
        currentDate(sigDate)
    {
        uint256 voteAmt = _getVoteAmount(ia, caller);

        Motion storage motion = _motions[ia];

        if (motion.allVoters.addVote(caller, voteAmt, sigDate, sigHash)) {
            motion.againstVoters.addVote(caller, voteAmt, sigDate, sigHash);
            emit Vote(ia, caller, false, voteAmt);
        }
    }

    function _getParas(address ia)
        private
        returns (uint256 totalHead, uint256 totalAmt)
    {
        Motion storage motion = _motions[ia];

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = motion.allVoters.qtyOfVoters();
        } else {
            uint32[] memory others = _agrmtCal.otherMembers(ia);

            totalHead = others.length;

            uint256 i;
            uint256 voteAmt;
            for (i = 0; i < totalHead; i++) {
                if (motion.votingRule.basedOnParOfVR()) {
                    voteAmt = _bos.parInHand(others[i]);
                } else {
                    voteAmt = _bos.paidInHand(others[i]);
                }

                if (
                    motion.allVoters.addVote(others[i], voteAmt, 0, bytes32(0))
                ) {
                    if (motion.votingRule.impliedConsentOfVR())
                        motion.supportVoters.addVote(
                            others[i],
                            voteAmt,
                            0,
                            bytes32(0)
                        );
                    else
                        motion.againstVoters.addVote(
                            others[i],
                            voteAmt,
                            0,
                            bytes32(0)
                        );
                }
            }
        }
        totalAmt = motion.allVoters.sumOfAmt();
    }

    function voteCounting(address ia)
        external
        onlyDirectKeeper
        onlyProposed(ia)
        onlyOnVoting(ia)
    {
        require(_boa.passedReview(ia), "Agreement NOT passed review");

        Motion storage motion = _motions[ia];

        require(
            now + 15 minutes > motion.sn.votingDeadlineOfMotion(),
            "voting NOT end"
        );

        (uint256 totalHead, uint256 totalAmt) = _getParas(ia);

        bool flag1 = motion.votingRule.ratioHeadOfVR() > 0
            ? totalHead > 0
                ? (motion.supportVoters.qtyOfVoters() * 10000) / totalHead >=
                    motion.votingRule.ratioHeadOfVR()
                : false
            : true;

        bool flag2 = motion.votingRule.ratioAmountOfVR() > 0
            ? totalAmt > 0
                ? (motion.supportVoters.sumOfAmt() * 10000) / totalAmt >=
                    motion.votingRule.ratioAmountOfVR()
                : false
            : true;

        motion.state = flag1 && flag2
            ? 2
            : motion.votingRule.againstShallBuyOfVR()
            ? 4
            : 3;

        emit VoteCounting(ia, motion.state);
    }

    function _ratioOfNay(address ia, uint32 againstVoter)
        private
        view
        returns (uint256)
    {
        Motion storage motion = _motions[ia];

        require(motion.state == 4, "agianst NO need to buy");
        require(motion.againstVoters.isVoter(againstVoter), "NOT NAY voter");

        return ((motion.againstVoters.amtOfVoter(againstVoter) * 10000) /
            motion.againstVoters.sumOfAmt());
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 execDate,
        uint32 againstVoter
    )
        external
        view
        onlyDirectKeeper
        currentDate(execDate)
        returns (uint256 parValue, uint256 paidPar)
    {
        uint256 ratio = _ratioOfNay(ia, againstVoter);

        (
            ,
            ,
            uint256 orgParValue,
            uint256 orgPaidPar,
            uint32 closingDate,
            ,

        ) = IAgreement(ia).getDeal(sn.sequenceOfDeal());

        require(execDate < closingDate, "MISSED closing date");

        require(
            execDate <
                _motions[ia].sn.votingDeadlineOfMotion() +
                    uint32(_motions[ia].votingRule.execDaysForPutOptOfVR()) *
                    86400,
            "MISSED execute deadline"
        );

        parValue = ((orgParValue * ratio) / 10000);
        paidPar = ((orgPaidPar * ratio) / 10000);
    }

    // function suspendVoting(address ia) external onlyProposed(ia) onlyKeeper {
    //     require(_motions[ia].state == 1, "NOT a proposed motion");
    //     _motions[ia].state = 5;
    //     emit SuspendVoting(ia);
    // }

    // function resumeVoting(address ia) external onlyProposed(ia) onlyKeeper {
    //     require(_motions[ia].state == 5, "NOT a suspend motion");
    //     _motions[ia].state = 1;
    //     emit ResumeVoting(ia);
    // }

    //##################
    //##    读接口    ##
    //##################

    function votingRule(address ia)
        external
        view
        onlyProposed(ia)
        returns (bytes32)
    {
        return _motions[ia].votingRule;
    }

    function state(address ia) external view onlyProposed(ia) returns (uint8) {
        return _motions[ia].state;
    }

    function votedYea(address ia, uint32 acct) external view returns (bool) {
        return _motions[ia].supportVoters.isVoter(acct);
    }

    function votedNay(address ia, uint32 acct) external view returns (bool) {
        return _motions[ia].supportVoters.isVoter(acct);
    }

    function getYea(address ia)
        external
        view
        returns (uint32[] membersOfYea, uint256 supportPar)
    {
        membersOfYea = _motions[ia].supportVoters.voters();
        supportPar = _motions[ia].supportVoters.sumOfAmt();
    }

    function getNay(address ia)
        external
        view
        returns (uint32[] membersOfNay, uint256 againstPar)
    {
        membersOfNay = _motions[ia].againstVoters.voters();
        againstPar = _motions[ia].againstVoters.sumOfAmt();
    }

    function sumOfVoteAmt(address ia) external view returns (uint256) {
        return _motions[ia].allVoters.sumOfAmt();
    }

    function isVoted(address ia, uint32 acct) public view returns (bool) {
        return _motions[ia].allVoters.isVoter(acct);
    }

    function getVote(address ia, uint32 acct)
        external
        view
        returns (
            bool attitude,
            uint32 date,
            uint256 amount,
            bytes32 sigHash
        )
    {
        require(isVoted(ia, acct), "did NOT vote");

        Motion storage motion = _motions[ia];

        attitude = motion.supportVoters.isVoter(acct);
        date = motion.allVoters.sigDate(acct);
        amount = motion.allVoters.amtOfVoter(acct);
        sigHash = motion.allVoters.sigHash(acct);
    }

    function isPassed(address ia)
        external
        view
        onlyProposed(ia)
        returns (bool)
    {
        return _motions[ia].state == 2;
    }

    function isRejected(address ia)
        external
        view
        onlyProposed(ia)
        returns (bool)
    {
        return _motions[ia].state == 3;
    }
}
