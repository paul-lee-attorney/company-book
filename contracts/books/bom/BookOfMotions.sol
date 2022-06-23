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
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/components/interfaces/ISigPage.sol";

contract BookOfMotions is SHASetting, BOASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjGroup for ObjGroup.VoterGroup;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Motion {
        bytes32 sn;
        bytes32 votingRule;
        EnumerableSet.UintSet supportVoters;
        uint256 sumOfYea;
        EnumerableSet.UintSet againstVoters;
        uint256 sumOfNay;
        ObjGroup.VoterGroup allVoters;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(not to buy) 4-rejected (to buy)
    }

    // ia/sha... => Motion
    mapping(address => Motion) private _motions;

    // Investment Agreements Subject to voting
    EnumerableSet.AddressSet private _ias;

    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(address indexed ia, bytes32 sn);

    event Vote(address indexed ia, uint40 voter, bool support, uint256 voteAmt);

    event VoteCounting(address indexed ia, uint8 result);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyProposed(address ia) {
        require(_ias.contains(ia), "IA is NOT isProposed");
        _;
    }

    modifier onlyOnVoting(address ia) {
        require(
            _motions[ia].state == uint8(EnumsRepo.StateOfMotion.Proposed),
            "Motion already voted"
        );
        _;
    }

    modifier beforeExpire(address ia, uint32 date) {
        require(
            date <= _motions[ia].sn.votingDeadlineOfMotion(),
            "missed voting deadline"
        );
        _;
    }

    modifier notVotedTo(address ia, uint40 caller) {
        require(!isVoted(ia, caller), "HAVE voted for the IA");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        address ia,
        uint40 submitter,
        uint32 proposeDate,
        uint32 votingDeadline
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.acctToSN(0, submitter);
        _sn = _sn.dateToSN(5, proposeDate);
        _sn = _sn.dateToSN(9, votingDeadline);
        _sn = _sn.addrToSN(13, ia);

        sn = _sn.bytesToBytes32();
    }

    function proposeMotion(
        address ia,
        uint32 proposeDate,
        uint40 submitter
    ) external onlyDirectKeeper {
        require(ISigPage(ia).established(), "doc is not established");

        require(
            !_ias.contains(ia),
            "the InvestmentAgreement has been proposed"
        );

        bytes32 rule = _getSHA().votingRules(_boa.typeOfIA(ia));

        Motion storage motion = _motions[ia];

        motion.votingRule = rule;
        motion.sn = _createSN(
            ia,
            submitter,
            proposeDate,
            _boa.votingDeadlineOf(ia)
        );
        motion.state = uint8(EnumsRepo.StateOfMotion.Proposed);

        if (_ias.add(ia)) emit ProposeMotion(ia, motion.sn);
    }

    function _getVoteAmount(address ia, uint40 caller)
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
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        notVotedTo(ia, caller)
        onlyOnVoting(ia)
        beforeExpire(ia, sigDate)
    {
        uint256 voteAmt = _getVoteAmount(ia, caller);

        Motion storage motion = _motions[ia];

        if (motion.allVoters.addVote(caller, voteAmt, sigDate, sigHash)) {
            motion.supportVoters.add(caller);
            motion.sumOfYea += voteAmt;
            emit Vote(ia, caller, true, voteAmt);
        }
    }

    function againstMotion(
        address ia,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        notVotedTo(ia, caller)
        onlyOnVoting(ia)
        beforeExpire(ia, sigDate)
    {
        uint256 voteAmt = _getVoteAmount(ia, caller);

        Motion storage motion = _motions[ia];

        if (motion.allVoters.addVote(caller, voteAmt, sigDate, sigHash)) {
            motion.againstVoters.add(caller);
            motion.sumOfNay += voteAmt;
            emit Vote(ia, caller, false, voteAmt);
        }
    }

    function _getParas(address ia) private returns (uint256 totalHead) {
        Motion storage motion = _motions[ia];

        if (motion.votingRule.onlyAttendanceOfVR()) {
            totalHead = motion.allVoters.voters.length;
        } else {
            uint40[] memory voters = motion.votingRule.partyAsConsentOfVR()
                ? _bos.members()
                : _boa.otherMembers(ia);

            totalHead = voters.length;

            uint256 i;
            uint256 voteAmt;

            for (i = 0; i < totalHead; i++) {
                if (_getSHA().basedOnPar()) {
                    voteAmt = _bos.parInHand(voters[i]);
                } else {
                    voteAmt = _bos.paidInHand(voters[i]);
                }

                if (
                    motion.allVoters.addVote(
                        voters[i],
                        voteAmt,
                        19450908,
                        bytes32(0)
                    )
                ) {
                    if (motion.votingRule.impliedConsentOfVR()) {
                        motion.supportVoters.add(voters[i]);
                        motion.sumOfYea += voteAmt;
                    } else if (
                        motion.votingRule.partyAsConsentOfVR() &&
                        ISigPage(ia).isParty(voters[i])
                    ) {
                        motion.supportVoters.add(voters[i]);
                        motion.sumOfYea += voteAmt;
                    }
                }
            }
        }
    }

    function voteCounting(address ia, uint32 sigDate)
        external
        onlyDirectKeeper
        onlyProposed(ia)
        onlyOnVoting(ia)
    {
        Motion storage motion = _motions[ia];

        require(sigDate > motion.sn.votingDeadlineOfMotion(), "voting NOT end");

        uint256 totalHead = _getParas(ia);

        bool flag1 = motion.votingRule.ratioHeadOfVR() > 0
            ? totalHead > 0
                ? (motion.supportVoters.length() * 10000) / totalHead >=
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
            ? uint8(EnumsRepo.StateOfMotion.Passed)
            : motion.votingRule.againstShallBuyOfVR()
            ? uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy)
            : uint8(EnumsRepo.StateOfMotion.Rejected_NotToBuy);

        emit VoteCounting(ia, motion.state);
    }

    function _ratioOfNay(address ia, uint40 againstVoter)
        private
        view
        returns (uint256)
    {
        Motion storage motion = _motions[ia];

        // require(
        //     motion.state == uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy),
        //     "agianst NO need to buy"
        // );
        require(
            motion.againstVoters.contains(uint256(againstVoter)),
            "NOT NAY voter"
        );

        return ((motion.allVoters.amtOfVoter[againstVoter] * 10000) /
            motion.sumOfNay);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 execDate,
        uint40 againstVoter
    )
        external
        view
        onlyDirectKeeper
        returns (uint256 parValue, uint256 paidPar)
    {
        // uint256 ratio = _ratioOfNay(ia, againstVoter);

        require(
            execDate <
                IInvestmentAgreement(ia).closingDate(sn.sequenceOfDeal()),
            "MISSED closing date"
        );

        require(
            execDate <
                _motions[ia].sn.votingDeadlineOfMotion() +
                    uint32(_motions[ia].votingRule.execDaysForPutOptOfVR()) *
                    86400,
            "MISSED execute deadline"
        );

        // parValue = ((orgParValue * ratio) / 10000);
        // paidPar = ((orgPaidPar * ratio) / 10000);

        (, parValue, paidPar, , ) = IInvestmentAgreement(ia).getDeal(
            sn.sequenceOfDeal()
        );
    }

    //##################
    //##    读接口    ##
    //##################

    function votingRule(address ia)
        external
        view
        onlyProposed(ia)
        onlyUser
        returns (bytes32)
    {
        return _motions[ia].votingRule;
    }

    function state(address ia)
        external
        view
        onlyProposed(ia)
        onlyUser
        returns (uint8)
    {
        return _motions[ia].state;
    }

    function votedYea(address ia, uint40 acct)
        external
        view
        onlyUser
        returns (bool)
    {
        return _motions[ia].supportVoters.contains(uint256(acct));
    }

    function votedNay(address ia, uint40 acct)
        external
        view
        onlyUser
        returns (bool)
    {
        return _motions[ia].againstVoters.contains(uint256(acct));
    }

    function getYea(address ia)
        external
        view
        onlyUser
        returns (uint40[] membersOfYea, uint256 supportPar)
    {
        membersOfYea = _motions[ia].supportVoters.valuesToUint40();
        supportPar = _motions[ia].sumOfYea;
    }

    function getNay(address ia)
        external
        view
        onlyUser
        returns (uint40[] membersOfNay, uint256 againstPar)
    {
        membersOfNay = _motions[ia].againstVoters.valuesToUint40();
        againstPar = _motions[ia].sumOfNay;
    }

    function sumOfVoteAmt(address ia) external view onlyUser returns (uint256) {
        return _motions[ia].allVoters.sumOfAmt;
    }

    function isVoted(address ia, uint40 acct)
        public
        view
        onlyUser
        returns (bool)
    {
        return _motions[ia].allVoters.sigDate[acct] > 0;
    }

    function getVote(address ia, uint40 acct)
        external
        view
        onlyUser
        returns (
            bool attitude,
            uint32 date,
            uint256 amount,
            bytes32 sigHash
        )
    {
        require(isVoted(ia, acct), "did NOT vote");

        Motion storage motion = _motions[ia];

        attitude = motion.supportVoters.contains(uint256(acct));
        date = motion.allVoters.sigDate[acct];
        amount = motion.allVoters.amtOfVoter[acct];
        sigHash = motion.allVoters.sigHash[acct];
    }

    function isPassed(address ia)
        external
        view
        onlyUser
        onlyProposed(ia)
        returns (bool)
    {
        return _motions[ia].state == uint8(EnumsRepo.StateOfMotion.Passed);
    }

    function isRejected(address ia)
        external
        view
        onlyUser
        onlyProposed(ia)
        returns (bool)
    {
        return _motions[ia].state > uint8(EnumsRepo.StateOfMotion.Passed);
    }
}
