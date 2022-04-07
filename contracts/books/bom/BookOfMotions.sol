/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/BOSSetting.sol";
import "../common/config/BOHSetting.sol";

import "../common/lib/ArrayUtils.sol";
import "../common/lib/serialNumber/VotingRuleParser.sol";

// import "../interfaces/IBookOfMotions.sol";
import "../interfaces/ISigPage.sol";
import "../interfaces/IAgreement.sol";

import "../common/component/EnumsRepo.sol";

import "../boh/interfaces/IVotingRules.sol";

contract BookOfMotions is EnumsRepo, BOSSetting, BOHSetting {
    using ArrayUtils for address[];
    using VotingRuleParser for bytes32;

    struct Motion {
        address ia;
        uint256 votingDeadline;
        mapping(address => uint256) sigOfYea;
        address[] membersOfYea;
        uint256 supportPar;
        mapping(address => uint256) sigOfNay;
        address[] membersOfNay;
        uint256 againstPar;
        mapping(address => bool) voted;
        mapping(address => uint256) voteAmt;
        uint256 sumOfVoteAmt;
        uint8 state; //动议状态 0-提案 1-提交 2-通过 3-否决(无代价) 4-否决（需购买）
    }

    // ia => Motion
    mapping(address => Motion) private _iaToMotion;

    // ia => bool
    mapping(address => bool) public isProposed;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(
        address indexed ia,
        uint256 votingDeadline,
        address proposedBy
    );

    event Vote(
        address indexed ia,
        address voter,
        bool support,
        uint256 voteAmt
    );

    event VoteCounting(address indexed ia, uint8 docType, uint8 result);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "NOT Admin of DOC"
        );
        _;
    }

    modifier notInternalST(address body) {
        require(IAgreement(body).typeOfIA() != 3, "NOT need to vote");
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
        require(_iaToMotion[ia].state == 1, "Motion already voted");
        _;
    }

    modifier beforeExpire(address ia) {
        require(
            now <= _iaToMotion[ia].votingDeadline,
            "missed voting deadline"
        );
        _;
    }

    modifier onlyVotedTo(address ia) {
        require(_iaToMotion[ia].voted[msg.sender], "NOT voted for the IA");
        _;
    }

    modifier notVotedTo(address ia) {
        require(!_iaToMotion[ia].voted[msg.sender], "HAVE voted for the IA");
        _;
    }

    modifier onlyPartyOfIA(address ia) {
        require(ISigPage(ia).isParty(msg.sender), "NOT a Party to the IA");
        _;
    }

    modifier notPartyOfIA(address ia) {
        require(!ISigPage(ia).isParty(msg.sender), "Party shall AVOID");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(address ia, uint256 votingDeadline)
        external
        onlyBookeeper
        notProposed(ia)
    {
        Motion storage motion = _iaToMotion[ia];

        motion.ia = ia;
        motion.votingDeadline = votingDeadline;
        motion.state = 1;

        isProposed[ia] = true;

        emit ProposeMotion(ia, votingDeadline, tx.origin);
    }

    function _getVoteAmount(address sender)
        private
        view
        returns (uint256 amount)
    {
        if (
            IVotingRules(getSHA().getTerm(uint8(TermTitle.VOTING_RULES)))
                .basedOnParValue()
        ) {
            (, amount, ) = _bos.getMember(sender);
        } else {
            (, , amount) = _bos.getMember(sender);
        }
    }

    function supportMotion(address ia, uint256 sigDate)
        external
        onlyMember
        notVotedTo(ia)
        onlyOnVoting(ia)
        beforeExpire(ia)
        notPartyOfIA(ia)
        currentDate(sigDate)
    {
        address sender = msg.sender;

        Motion storage motion = _iaToMotion[ia];

        motion.sigOfYea[sender] = sigDate;
        motion.membersOfYea.push(sender);

        uint256 voteAmt = _getVoteAmount(sender);

        motion.supportPar += voteAmt;
        motion.voteAmt[sender] = voteAmt;
        motion.sumOfVoteAmt += voteAmt;
        motion.voted[sender] = true;

        emit Vote(ia, sender, true, voteAmt);
    }

    function againstMotion(address ia, uint256 sigDate)
        external
        onlyMember
        notVotedTo(ia)
        notPartyOfIA(ia)
        onlyOnVoting(ia)
        beforeExpire(ia)
        currentDate(sigDate)
    {
        address sender = msg.sender;

        Motion storage motion = _iaToMotion[ia];

        motion.sigOfNay[sender] = sigDate;
        motion.membersOfNay.push(sender);

        uint256 voteAmt = _getVoteAmount(sender);

        motion.againstPar += voteAmt;
        motion.voteAmt[sender] = voteAmt;
        motion.sumOfVoteAmt += voteAmt;
        motion.voted[sender] = true;

        emit Vote(ia, sender, false, voteAmt);
    }

    function _getParas(uint8 votingType, Motion storage motion)
        private
        returns (
            uint256 ratioHead,
            uint256 ratioAmount,
            uint256 totalHead,
            uint256 totalAmt,
            bool againstShallBuy
        )
    {
        bytes32 rule = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        ).rules(votingType);

        ratioHead = rule.ratioHead();
        ratioAmount = rule.ratioAmount();
        againstShallBuy = rule.agianstShallBuy();

        address[] storage memberSigners = ISigPage(ia).singers();
        address[] storage otherMembers = _bos.membersList();
        uint256 i;

        for (i = 0; i < memberSigners.length; i++) {
            (bool exist, ) = otherMembers.firstIndexOf(memberSigners[i]);
            if (exist) otherMembers.removeByValue(memberSigners[i]);
            else memberSigners.removeByValue(memberSigners[i]);
        }

        totalHead = otherMembers.length;

        for (i = 0; i < otherMembers.length; i++) {
            (, uint256 parValue, uint256 paidPar) = _bos.getMember(
                otherMembers[i]
            );
            totalAmt = rule.basedOnParValue() ? parValue : paidPar;
        }

        if (rule.impliedConsent()) {
            motion.supportPar += (totalAmt - motion.sumOfVoteAmt);

            for (uint8 i = 0; i < otherMembers.length; i++) {
                if (!motion.voted[otherMembers[i]])
                    motion.membersOfYea.push(otherMembers[i]);
            }
        }

        if (rule.onlyAttendance()) {
            totalHead = motion.membersOfYea.length + motion.membersOfNay.length;
            totalAmt = motion.sumOfVoteAmt;
        }
    }

    function voteCounting(address ia, uint8 votingType) external onlyBookeeper {
        Motion storage motion = _iaToMotion[ia];

        (
            uint256 ratioHead,
            uint256 ratioAmount,
            uint256 totalHead,
            uint256 totalAmt,
            bool againstShallBuy
        ) = _getParas(votingType, motion);

        bool flag1 = ratioHead > 0
            ? totalHead > 0
                ? (motion.membersOfYea.length * 10000) / totalHead >= ratioHead
                : false
            : true;

        bool flag2 = ratioAmount > 0
            ? totalAmt > 0
                ? (motion.supportPar * 10000) / totalAmt >= ratioAmount
                : false
            : true;

        motion.state = flag1 && flag2 ? 2 : againstShallBuy ? 4 : 3;

        emit VoteCounting(ia, votingType, motion.state);
    }

    //##################
    //##    读接口    ##
    //##################

    function getVotingDeadline(address ia)
        external
        view
        onlyProposed(ia)
        returns (uint256)
    {
        return _iaToMotion[ia].votingDeadline;
    }

    function getState(address ia)
        external
        view
        onlyProposed(ia)
        returns (uint8)
    {
        return _iaToMotion[ia].state;
    }

    function votedYea(address ia, address acct) external view returns (bool) {
        return _iaToMotion[ia].sigOfYea[acct] > 0;
    }

    function votedNay(address ia, address acct) external view returns (bool) {
        return _iaToMotion[ia].sigOfNay[acct] > 0;
    }

    function getYea(address ia)
        external
        view
        returns (address[] membersOfYea, uint256 supportPar)
    {
        membersOfYea = _iaToMotion[ia].membersOfYea;
        supportPar = _iaToMotion[ia].supportPar;
    }

    function getNay(address ia)
        external
        view
        returns (address[] membersOfNay, uint256 againstPar)
    {
        membersOfNay = _iaToMotion[ia].membersOfNay;
        againstPar = _iaToMotion[ia].againstPar;
    }

    function getSumOfVoteAmt(address ia) external view returns (uint256) {
        return _iaToMotion[ia].sumOfVoteAmt;
    }

    function haveVoted(address ia, address acct) public view returns (bool) {
        return _iaToMotion[ia].voted[acct];
    }

    function getVote(address ia, address acct)
        external
        view
        returns (
            bool attitude,
            uint256 date,
            uint256 amount
        )
    {
        require(haveVoted(ia, acct), "did NOT vote");

        Motion memory motion = _iaToMotion(ia);
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
        return _iaToMotion[ia].state == 2;
    }

    function isRejected(address ia)
        external
        view
        onlyProposed(ia)
        returns (bool)
    {
        return _iaToMotion[ia].state == 3;
    }
}
