/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../boa/interfaces/IInvestmentAgreement.sol";

import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/ObjGroup.sol";
import "../../common/lib/ObjGroup.sol";
import "../../common/lib/ObjGroup.sol";

import "../../common/components/interfaces/ISigPage.sol";

contract BookOfMotions is SHASetting, BOASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.UserGroup;
    using ObjGroup for ObjGroup.VoterGroup;
    using ObjGroup for ObjGroup.AddrList;

    struct Motion {
        bytes32 sn;
        bytes32 votingRule;
        ObjGroup.UserGroup supportVoters;
        uint256 sumOfYea;
        ObjGroup.UserGroup againstVoters;
        uint256 sumOfNay;
        ObjGroup.VoterGroup allVoters;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(not to buy) 4-rejected (to buy)
    }

    // ia/sha... => Motion
    mapping(address => Motion) private _motions;

    // Investment Agreements Subject to voting
    ObjGroup.AddrList private _ias;

    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(address indexed ia, bytes32 sn);

    event Vote(address indexed ia, uint32 voter, bool support, uint256 voteAmt);

    event VoteCounting(address indexed ia, uint8 result);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyProposed(address ia) {
        require(_ias.isItem[ia], "IA is NOT isProposed");
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
        require(!isVoted(ia, caller), "HAVE voted for the IA");
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
            "InvestmentAgreement not passed review procesedure"
        );

        require(!_ias.isItem[ia], "the InvestmentAgreement has been proposed");

        bytes32 rule = _getSHA().votingRules(_boa.typeOfIA(ia));

        uint32 votingDeadline = proposeDate +
            uint32(rule.votingDaysOfVR()) *
            86400;

        Motion storage motion = _motions[ia];

        motion.votingRule = rule;
        motion.sn = _createSN(ia, submitter, proposeDate, votingDeadline);
        motion.state = 1;

        if (_ias.addItem(ia)) emit ProposeMotion(ia, motion.sn);
    }

    function _getVoteAmount(address ia, uint32 caller)
        private
        view
        returns (uint256 amount)
    {
        if (_getSHA().basedOnPar()) {
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
            motion.supportVoters.addMember(caller);
            motion.sumOfYea += voteAmt;
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
            motion.againstVoters.addMember(caller);
            motion.sumOfNay += voteAmt;
            emit Vote(ia, caller, false, voteAmt);
        }
    }

    function _getParas(address ia) private returns (uint256 totalHead) {
        Motion storage motion = _motions[ia];

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = motion.allVoters.voters.length;
        } else {
            uint32[] memory others = _boa.otherMembers(ia);

            totalHead = others.length;

            uint256 i;
            uint256 voteAmt;

            for (i = 0; i < totalHead; i++) {
                if (_getSHA().basedOnPar()) {
                    voteAmt = _bos.parInHand(others[i]);
                } else {
                    voteAmt = _bos.paidInHand(others[i]);
                }

                if (
                    motion.allVoters.addVote(
                        others[i],
                        voteAmt,
                        19770919,
                        bytes32(0)
                    )
                ) {
                    if (motion.votingRule.impliedConsentOfVR()) {
                        motion.supportVoters.addMember(others[i]);
                        motion.sumOfYea += voteAmt;
                    }
                }
            }
        }
    }

    function voteCounting(address ia)
        external
        onlyDirectKeeper
        onlyProposed(ia)
        onlyOnVoting(ia)
    {
        require(_boa.passedReview(ia), "InvestmentAgreement NOT passed review");

        Motion storage motion = _motions[ia];

        require(
            now + 15 minutes > motion.sn.votingDeadlineOfMotion(),
            "voting NOT end"
        );

        uint256 totalHead = _getParas(ia);

        bool flag1 = motion.votingRule.ratioHeadOfVR() > 0
            ? totalHead > 0
                ? (motion.supportVoters.members.length * 10000) / totalHead >=
                    motion.votingRule.ratioHeadOfVR()
                : false
            : true;

        bool flag2 = motion.votingRule.ratioAmountOfVR() > 0
            ? motion.allVoters.sumOfAmt > 0
                ? (motion.sumOfYea * 10000) / motion.allVoters.sumOfAmt >=
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
        require(motion.againstVoters.isMember[againstVoter], "NOT NAY voter");

        return ((motion.allVoters.amtOfVoter[againstVoter] * 10000) /
            motion.sumOfNay);
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

        (, uint256 orgParValue, uint256 orgPaidPar, , ) = IInvestmentAgreement(
            ia
        ).getDeal(sn.sequenceOfDeal());

        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

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
        return _motions[ia].supportVoters.isMember[acct];
    }

    function votedNay(address ia, uint32 acct) external view returns (bool) {
        return _motions[ia].againstVoters.isMember[acct];
    }

    function getYea(address ia)
        external
        view
        returns (uint32[] membersOfYea, uint256 supportPar)
    {
        membersOfYea = _motions[ia].supportVoters.members;
        supportPar = _motions[ia].sumOfYea;
    }

    function getNay(address ia)
        external
        view
        returns (uint32[] membersOfNay, uint256 againstPar)
    {
        membersOfNay = _motions[ia].againstVoters.members;
        againstPar = _motions[ia].sumOfNay;
    }

    function sumOfVoteAmt(address ia) external view returns (uint256) {
        return _motions[ia].allVoters.sumOfAmt;
    }

    function isVoted(address ia, uint32 acct) public view returns (bool) {
        return _motions[ia].allVoters.sigDate[acct] > 0;
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

        attitude = motion.supportVoters.isMember[acct];
        date = motion.allVoters.sigDate[acct];
        amount = motion.allVoters.amtOfVoter[acct];
        sigHash = motion.allVoters.sigHash[acct];
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
