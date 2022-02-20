/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;
// pragma experimental ABIEncoderV2;

import "../config/BOSSetting.sol";
import "../config/BOHSetting.sol";

import "../interfaces/IBookOfMotions.sol";
import "../interfaces/ISigPage.sol";
import "../interfaces/IAgreement.sol";

import "../common/EnumsRepo.sol";

import "../sha/interfaces/IVotingRules.sol";

contract BookOfMotions is IBookOfMotions, EnumsRepo, BOSSetting, BOHSetting {
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
        uint256 votedPar;
        uint8 state; //动议状态 0-提案 1-提交 2-通过 3-否决
    }

    // ia => Motion
    mapping(address => Motion) private _iaToMotion;

    // ia => bool
    mapping(address => bool) private _proposed;

    uint256 private _qtyOfMotions;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    //####################
    //##    modifier    ##
    //####################

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "仅文件 管理员 可操作"
        );
        _;
    }

    modifier notInternalST(address body) {
        require(IAgreement(body).getTypeOfIA() != 3, "无需表决");
        _;
    }

    modifier notProposed(address ia) {
        require(!_proposed[ia], "投资协议 已提案");
        _;
    }

    modifier onlyProposed(address ia) {
        require(_proposed[ia], "投资协议 未提案");
        _;
    }

    modifier onlyOnVoting(address ia) {
        require(_iaToMotion[ia].state == 1, "动议 已唱票");
        _;
    }

    modifier beforeExpire(address ia) {
        require(now <= _iaToMotion[ia].votingDeadline, "已过截止期");
        _;
    }

    modifier afterExpire(address ia) {
        require(now > _iaToMotion[ia].votingDeadline, "表决期间尚未届满");
        _;
    }

    modifier onlyVotedTo(address ia) {
        require(_iaToMotion[ia].voted[msg.sender], "没投过票");
        _;
    }

    modifier notVotedTo(address ia) {
        require(!_iaToMotion[ia].voted[msg.sender], "已投过票");
        _;
    }

    modifier onlyPartyOfIA(address ia) {
        require(ISigPage(ia).isParty(msg.sender), "只有当事方可操作");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(address ia, uint8 votingDays)
        external
        onlyBookeeper
        notProposed(ia)
        notInternalST(ia)
    {
        Motion storage motion = _iaToMotion[ia];

        motion.ia = ia;
        motion.votingDeadline = now + uint256(votingDays) * 86400;
        motion.state = 1;

        _proposed[ia] = true;

        emit ProposeMotion(ia, motion.votingDeadline, msg.sender);
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

    function supportMotion(address ia)
        external
        onlyMember
        notVotedTo(ia)
        onlyOnVoting(ia)
        beforeExpire(ia)
    {
        address sender = msg.sender;

        Motion motion = _iaToMotion[ia];

        motion.sigOfYea[sender] = now;
        motion.membersOfYea.push(sender);

        uint256 voteAmt = _getVoteAmount(sender);

        motion.supportPar += voteAmt;
        motion.votedPar += voteAmt;
        motion.voted[sender] = true;

        emit Vote(ia, sender, true, voteAmt);
    }

    function againstMotion(address ia)
        external
        onlyMember
        notVotedTo(ia)
        onlyOnVoting(ia)
        beforeExpire(ia)
    {
        address sender = msg.sender;

        Motion motion = _iaToMotion[ia];

        motion.sigOfNay[sender] = now;
        motion.membersOfNay.push(sender);

        uint256 voteAmt = _getVoteAmount(sender);

        motion.againstPar += voteAmt;
        motion.votedPar += voteAmt;
        motion.voted[sender] = true;

        emit Vote(ia, sender, false, voteAmt);
    }

    function _getVotingType(address ia)
        private
        view
        returns (uint8 votingType)
    {
        uint8 typeOfIA = IAgreement(ia).getTypeOfIA();

        votingType = (typeOfIA == 2 || typeOfIA == 5) ? 2 : (typeOfIA == 3)
            ? 0
            : 1;
    }

    function _getParas(uint8 votingType, Motion storage motion)
        private
        returns (
            uint256 ratioHead,
            uint256 ratioAmount,
            uint256 totalHead,
            uint256 totalAmt
        )
    {
        IVotingRules rules = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        );

        bool onlyVoted;
        bool impliedConsent;

        (ratioHead, ratioAmount, onlyVoted, impliedConsent, , ) = rules.getRule(
            votingType
        );

        totalHead = _bos.getQtyOfMembers();

        totalAmt = rules.basedOnParValue()
            ? _bos.getRegCap()
            : _bos.getPaidInCap();

        if (impliedConsent) {
            motion.supportPar += (totalAmt - motion.votedPar);

            address[] memory members = _bos.getMemberList();
            for (uint8 i = 0; i < members.length; i++) {
                if (!motion.voted[members[i]])
                    motion.membersOfYea.push(members[i]);
            }
        }

        if (onlyVoted) {
            totalHead = motion.membersOfYea.length + motion.membersOfNay.length;
            totalAmt = motion.votedPar;
        }
    }

    function _updateState(Motion storage motion, uint8 votingType) private {
        (
            uint256 ratioHead,
            uint256 ratioAmount,
            uint256 totalHead,
            uint256 totalAmt
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

        motion.state = flag1 && flag2 ? 2 : 3;
    }

    function voteCounting(address ia)
        external
        onlyPartyOfIA(ia)
        onlyOnVoting(ia)
        afterExpire(ia)
    {
        Motion storage motion = _iaToMotion[ia];

        uint8 votingType = _getVotingType(ia);

        if (votingType > 0) {
            _updateState(motion, votingType);
            emit VoteCounting(ia, votingType, motion.state);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function votedYea(address ia, address acct)
        public
        onlyStakeholders
        returns (bool)
    {
        return _iaToMotion[ia].sigOfYea[acct] > 0;
    }

    function votedNay(address ia, address acct)
        public
        onlyStakeholders
        returns (bool)
    {
        return _iaToMotion[ia].sigOfNay[acct] > 0;
    }

    function getYea(address ia)
        public
        onlyStakeholders
        returns (address[] membersOfYea, uint256 supportPar)
    {
        membersOfYea = _iaToMotion[ia].membersOfYea;
        supportPar = _iaToMotion[ia].supportPar;
    }

    function getNay(address ia)
        public
        onlyStakeholders
        returns (address[] membersOfNay, uint256 againstPar)
    {
        membersOfNay = _iaToMotion[ia].membersOfNay;
        againstPar = _iaToMotion[ia].againstPar;
    }

    function haveVoted(address ia, address acct)
        public
        onlyStakeholders
        returns (bool)
    {
        return _iaToMotion[ia].voted[acct];
    }

    function getVotedPar(address ia) public onlyStakeholders returns (uint256) {
        return _iaToMotion[ia].votedPar;
    }

    function getVoteDate(address ia, address acct)
        external
        onlyVotedTo(ia)
        onlyStakeholders
        returns (uint256 date)
    {
        Motion storage motion = _iaToMotion[ia];
        date = motion.sigOfYea[acct] > 0
            ? motion.sigOfYea[acct]
            : motion.sigOfNay[acct];
    }

    function isProposed(address ia)
        external
        onlyProposed(ia)
        onlyStakeholders
        returns (bool)
    {
        return _proposed[ia];
    }

    function isPassed(address ia)
        external
        onlyProposed(ia)
        onlyStakeholders
        returns (bool)
    {
        return _iaToMotion[ia].state == 2;
    }
}
