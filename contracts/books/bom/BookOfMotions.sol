/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../boa/interfaces/IAgreement.sol";

// import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNParser.sol";

import "../../common/components/interfaces/ISigPage.sol";
import "../../common/access/interfaces/IAccessControl.sol";

import "../../common/components/EnumsRepo.sol";

contract BookOfMotions is EnumsRepo, SHASetting, BOASetting, BOSSetting {
    using ArrayUtils for uint32[];
    using SNParser for bytes32;

    struct Motion {
        bytes32 votingRule;
        uint32 votingDeadline;
        mapping(address => uint32) sigOfYea;
        uint32[] membersOfYea;
        uint256 supportPar;
        mapping(address => uint32) sigOfNay;
        uint32[] membersOfNay;
        uint256 againstPar;
        mapping(uint32 => bool) voted;
        mapping(uint32 => uint256) voteAmt;
        uint256 sumOfVoteAmt;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(no need to buy) 4-rejected (against need to buy) 5-suspend
    }

    // ia => Motion
    mapping(address => Motion) private _motions;

    // ia => bool
    mapping(address => bool) public isProposed;

    // constructor(address bookeeper) public {
    //     init(msg.sender, bookeeper);
    // }

    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(
        address indexed ia,
        uint32 votingDeadline,
        uint32 proposedBy
    );

    event Vote(address indexed ia, uint32 voter, bool support, uint256 voteAmt);

    event TurnOverVote(address indexed ia, uint32 voter, uint256 voteAmt);

    event VoteCounting(address indexed ia, uint8 result);

    event SuspendVoting(address indexed ia);

    event ResumeVoting(address indexed ia);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyAdminOf(address body) {
        require(
            IAccessControl(body).getOwner() == _msgSender(),
            "NOT Admin of DOC"
        );
        _;
    }

    modifier notInternalST(address body) {
        require(_agrmtCal.typeOfIA(body) != 3, "NOT need to vote");
        _;
    }

    modifier notProposed(address ia) {
        require(!isProposed[ia], "IA has been isProposed");
        _;
    }

    modifier onlyProposed(address ia) {
        require(isProposed[ia], "IA is NOT isProposed");
        _;
    }

    modifier onlyOnVoting(address ia) {
        require(_motions[ia].state == 1, "Motion already voted");
        _;
    }

    modifier beforeExpire(address ia) {
        require(now <= _motions[ia].votingDeadline, "missed voting deadline");
        _;
    }

    modifier onlyVotedTo(address ia) {
        require(_motions[ia].voted[_msgSender()], "NOT voted for the IA");
        _;
    }

    modifier notVotedTo(address ia) {
        require(!_motions[ia].voted[_msgSender()], "HAVE voted for the IA");
        _;
    }

    modifier onlyPartyOfIA(address ia) {
        require(ISigPage(ia).isParty(_msgSender()), "NOT a Party to the IA");
        _;
    }

    modifier notPartyOfIA(address ia) {
        require(!ISigPage(ia).isParty(_msgSender()), "Party shall AVOID");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(
        address ia,
        uint32 proposeDate,
        uint32 submitter
    ) external onlyKeeper notProposed(ia) {
        require(_boa.isSubmitted(ia), "Agreement NOT submitted");

        bytes32 rule = _getSHA().votingRules(_agrmtCal.typeOfIA(ia));

        Motion storage motion = _motions[ia];

        motion.votingRule = rule;
        motion.votingDeadline =
            proposeDate +
            uint32(rule.votingDaysOfVR()) *
            86400;
        motion.state = 1;

        isProposed[ia] = true;

        emit ProposeMotion(ia, motion.votingDeadline, submitter);
    }

    function _getVoteAmount(address ia, uint32 sender)
        private
        view
        returns (uint256 amount)
    {
        if (_motions[ia].votingRule.basedOnParOfVR()) {
            amount = _bos.parInHand(sender);
        } else {
            amount = _bos.paidInHand(sender);
        }
    }

    function supportMotion(address ia, uint32 sigDate)
        external
        onlyMember
        notVotedTo(ia)
        onlyOnVoting(ia)
        beforeExpire(ia)
        notPartyOfIA(ia)
        currentDate(sigDate)
    {
        require(_boa.isSubmitted(ia), "Agreement NOT submitted");

        uint32 sender = _msgSender();

        Motion storage motion = _motions[ia];

        motion.sigOfYea[msg.sender] = sigDate;
        motion.membersOfYea.push(sender);

        uint256 voteAmt = _getVoteAmount(ia, sender);

        motion.supportPar += voteAmt;
        motion.voteAmt[sender] = voteAmt;
        motion.sumOfVoteAmt += voteAmt;
        motion.voted[sender] = true;

        emit Vote(ia, sender, true, voteAmt);
    }

    function againstMotion(address ia, uint32 sigDate)
        external
        onlyMember
        notVotedTo(ia)
        notPartyOfIA(ia)
        onlyOnVoting(ia)
        beforeExpire(ia)
        currentDate(sigDate)
    {
        require(_boa.isSubmitted(ia), "Agreement NOT submitted");

        uint32 sender = _msgSender();

        Motion storage motion = _motions[ia];

        motion.sigOfNay[msg.sender] = sigDate;
        motion.membersOfNay.push(sender);

        uint256 voteAmt = _getVoteAmount(ia, sender);

        motion.againstPar += voteAmt;
        motion.voteAmt[sender] = voteAmt;
        motion.sumOfVoteAmt += voteAmt;
        motion.voted[sender] = true;

        emit Vote(ia, sender, false, voteAmt);
    }

    function _getParas(address ia)
        private
        returns (uint256 totalHead, uint256 totalAmt)
    {
        Motion storage motion = _motions[ia];

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = motion.membersOfYea.length + motion.membersOfNay.length;
            totalAmt = motion.sumOfVoteAmt;
        } else {
            uint32[] memory others = _agrmtCal.otherMembers(ia);

            totalHead = others.length;

            uint256 i;
            for (i = 0; i < totalHead; i++) {
                if (motion.votingRule.basedOnParOfVR()) {
                    totalAmt += _bos.parInHand(others[i]);
                } else {
                    totalAmt += _bos.paidInHand(others[i]);
                }
            }

            if (motion.votingRule.impliedConsentOfVR()) {
                motion.supportPar += (totalAmt - motion.sumOfVoteAmt);

                for (i = 0; i < totalHead; i++)
                    if (!motion.voted[others[i]])
                        motion.membersOfYea.push(others[i]);
            }
        }
    }

    function voteCounting(address ia)
        external
        onlyKeeper
        onlyProposed(ia)
        onlyOnVoting(ia)
    {
        require(_boa.isSubmitted(ia), "Agreement NOT submitted");

        Motion storage motion = _motions[ia];

        require(now + 15 minutes > motion.votingDeadline, "voting NOT end");

        (uint256 totalHead, uint256 totalAmt) = _getParas(ia);

        bool flag1 = motion.votingRule.ratioHeadOfVR() > 0
            ? totalHead > 0
                ? (motion.membersOfYea.length * 10000) / totalHead >=
                    motion.votingRule.ratioHeadOfVR()
                : false
            : true;

        bool flag2 = motion.votingRule.ratioAmountOfVR() > 0
            ? totalAmt > 0
                ? (motion.supportPar * 10000) / totalAmt >=
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
        require(motion.sigOfNay[againstVoter] > 0, "NOT NAY voter");

        return ((motion.voteAmt[againstVoter] * 10000) / motion.againstPar);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        uint32 againstVoter
    )
        external
        view
        onlyKeeper
        currentDate(exerciseDate)
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

        require(exerciseDate < closingDate, "MISSED closing date");

        require(
            exerciseDate <
                _motions[ia].votingDeadline +
                    uint32(_motions[ia].votingRule.execDaysForPutOptOfVR()) *
                    86400,
            "MISSED execute deadline"
        );

        parValue = ((orgParValue * ratio) / 10000);
        paidPar = ((orgPaidPar * ratio) / 10000);
    }

    function suspendVoting(address ia) external onlyProposed(ia) onlyKeeper {
        require(_motions[ia].state == 1, "NOT a proposed motion");
        _motions[ia].state = 5;
        emit SuspendVoting(ia);
    }

    function resumeVoting(address ia) external onlyProposed(ia) onlyKeeper {
        require(_motions[ia].state == 5, "NOT a suspend motion");
        _motions[ia].state = 1;
        emit ResumeVoting(ia);
    }

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

    function votingDeadline(address ia)
        external
        view
        onlyProposed(ia)
        returns (uint32)
    {
        return _motions[ia].votingDeadline;
    }

    function state(address ia) external view onlyProposed(ia) returns (uint8) {
        return _motions[ia].state;
    }

    function votedYea(address ia, uint32 acct) external view returns (bool) {
        return _motions[ia].sigOfYea[acct] > 0;
    }

    function votedNay(address ia, uint32 acct) external view returns (bool) {
        return _motions[ia].sigOfNay[acct] > 0;
    }

    function getYea(address ia)
        external
        view
        returns (uint32[] membersOfYea, uint256 supportPar)
    {
        membersOfYea = _motions[ia].membersOfYea;
        supportPar = _motions[ia].supportPar;
    }

    function getNay(address ia)
        external
        view
        returns (uint32[] membersOfNay, uint256 againstPar)
    {
        membersOfNay = _motions[ia].membersOfNay;
        againstPar = _motions[ia].againstPar;
    }

    function sumOfVoteAmt(address ia) external view returns (uint256) {
        return _motions[ia].sumOfVoteAmt;
    }

    function isVoted(address ia, uint32 acct) public view returns (bool) {
        return _motions[ia].voted[acct];
    }

    function getVote(address ia, uint32 acct)
        external
        view
        returns (
            bool attitude,
            uint32 date,
            uint256 amount
        )
    {
        require(isVoted(ia, acct), "did NOT vote");

        Motion storage motion = _motions[ia];
        attitude = motion.sigOfYea[acct] > 0;
        date = attitude ? motion.sigOfYea[acct] : motion.sigOfNay[acct];
        amount = motion.voteAmt[acct];
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
