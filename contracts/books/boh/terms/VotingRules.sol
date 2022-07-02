/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../../common/access/DraftControl.sol";

import "../../../common/lib/SNFactory.sol";

import "./IVotingRules.sol";

contract VotingRules is IVotingRules, DraftControl {
    using SNFactory for bytes;

    // struct snInfo {
    //     uint16 ratioHead;
    //     uint16 ratioAmount;
    //     bool onlyAttendance;
    //     bool impliedConsent;
    //     bool partyAsConsent;
    //     bool againstShallBuy;
    //     uint8 reviewDays; //default: 15 natural days
    //     uint8 votingDays; //default: 30 natrual days
    //     uint8 execDaysForPutOpt; //default: 7 natrual days
    //     uint8 typeOfVote;
    // }

    // typeOfVote => Rule: 1-CI 2-ST(to 3rd Party) 3-ST(to otherMember) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    bytes32[12] private _votingRules;

    // bool private _basedOnPar;

    // uint256 private _proposalThreshold;

    struct Governance {
        bool basedOnPar;
        uint16 proposalThreshold;
        uint8 maxNumOfDirectors;
        uint8 tenureOfBoard;
        uint40 nominatorOfChairman;
        uint40 nominatorOfViceChairman;
        uint8 sumOfBoardSeatsQuota;
        mapping(uint40 => uint8) boardSeatsQuotaOf;
    }

    Governance private _ruleOfGovernance;

    // constructor() public {
    //     // votingDays = 30; // default 30 days as per Company Law Act

    //     //                                            2    4           8          12
    //     // default for Capital Increase : (10进制) 0000 6666 00 00 01 00 15 30 00 01
    //     _votingRules[
    //         1
    //     ] = 0x00004242000001000f1e00010000000000000000000000000000000000000000;

    //     _votingRules[
    //         4
    //     ] = 0x00004242000001000f1e00040000000000000000000000000000000000000000;

    //     _votingRules[
    //         6
    //     ] = 0x00004242000001000f1e07060000000000000000000000000000000000000000;

    //     _votingRules[
    //         7
    //     ] = 0x00004242000001000f1e07070000000000000000000000000000000000000000;

    //     // default for Share Transfer : (10进制) 0000 5000 00 01 00 01 15 30 07 02
    //     _votingRules[
    //         2
    //     ] = 0x00003200000100010f1e07020000000000000000000000000000000000000000;

    //     _votingRules[
    //         3
    //     ] = 0x0000000000000000000000030000000000000000000000000000000000000000;

    //     _votingRules[
    //         5
    //     ] = 0x00003200000100010f1e07050000000000000000000000000000000000000000;
    // }

    // ################
    // ##   Event    ##
    // ################

    event SetVotingBaseOnPar();

    event SetProposalThreshold(uint256 threshold);

    event SetRule(uint8 typeOfVote, bytes32 sn);

    // ################
    // ##  Modifier  ##
    // ################

    modifier typeAllowed(uint8 typeOfVote) {
        require(typeOfVote < 12, "typeOfVote overflow");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setVotingBaseOnPar() external onlyAttorney {
        _ruleOfGovernance.basedOnPar = true;
        emit SetVotingBaseOnPar();
    }

    function setProposalThreshold(uint16 threshold) external onlyAttorney {
        _ruleOfGovernance.proposalThreshold = threshold;
        emit SetProposalThreshold(threshold);
    }

    function setMaxNumOfDirectors(uint8 num) external onlyAttorney {
        _ruleOfGovernance.maxNumOfDirectors = num;
        emit SetMaxNumOfDirectors(num);
    }

    function setTenureOfBoard(uint8 numOfYear) external onlyAttorney {
        _ruleOfGovernance.tenureOfBoard = numOfYear;
        emit SetTenureOfBoard(numOfYear);
    }

    function setNominatorOfChairman(uint40 nominator) external onlyAttorney {
        _ruleOfGovernance.nominatorOfChairman = nominator;
        emit SetNominatorOfChairman(nominator);
    }

    function setNominatorOfViceChairman(uint40 nominator)
        external
        onlyAttorney
    {
        _ruleOfGovernance.nominatorOfViceChairman = nominator;
        emit SetNominatorOfViceChairman(nominator);
    }

    function setBoardSeatsQuotaOf(uint40 nominator, uint8 quota)
        external
        onlyAttorney
    {
        uint8 orgQuota = _ruleOfGovernance.boardSeatsQuotaOf[nominator];

        if (orgQuota > 0) {
            require(
                _ruleOfGovernance.sumOfBoardSeatsQuota - orgQuota + quota <=
                    _ruleOfGovernance.maxNumOfDirectors,
                "board seats quota overflow"
            );
            _ruleOfGovernance.sumOfBoardSeatsQuota -= orgQuota;
        } else {
            require(
                _ruleOfGovernance.sumOfBoardSeatsQuota + quota <=
                    _ruleOfGovernance.maxNumOfDirectors,
                "board seats quota overflow"
            );
        }

        _ruleOfGovernance.boardSeatsQuotaOf[nominator] = quota;
        _ruleOfGovernance.sumOfBoardSeatsQuota += quota;

        emit SetBoardSeatsQuotaOf(nominator, quota);
    }

    function setRule(
        uint8 typeOfVote,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool partyAsConsent,
        bool againstShallBuy,
        uint8 reviewDays,
        uint8 votingDays,
        uint8 execDaysForPutOpt
    ) external onlyAttorney typeAllowed(typeOfVote) {
        require(votingDays > 0, "ZERO votingDays");

        bytes memory _sn = new bytes(32);

        _sn = _sn.intToSN(0, ratioHead, 2);
        _sn = _sn.intToSN(2, ratioAmount, 2);
        _sn = _sn.boolToSN(4, onlyAttendance);
        _sn = _sn.boolToSN(5, impliedConsent);
        _sn = _sn.boolToSN(6, partyAsConsent);
        _sn = _sn.boolToSN(7, againstShallBuy);
        _sn[8] = bytes1(reviewDays);
        _sn[9] = bytes1(votingDays);
        _sn[10] = bytes1(execDaysForPutOpt);
        _sn[11] = bytes1(typeOfVote);

        _votingRules[typeOfVote] = _sn.bytesToBytes32();

        emit SetRule(typeOfVote, _votingRules[typeOfVote]);
    }

    // ################
    // ##   读接口   ##
    // ################

    function votingRules(uint8 typeOfVote)
        external
        view
        onlyUser
        returns (bytes32)
    {
        return _votingRules[typeOfVote];
    }

    function basedOnPar() external view onlyUser returns (bool) {
        return _ruleOfGovernance.basedOnPar;
    }

    function proposalThreshold() external view onlyUser returns (uint16) {
        return _ruleOfGovernance.proposalThreshold;
    }

    function maxNumOfDirectors() external view onlyUser returns (uint8) {
        return _ruleOfGovernance.maxNumOfDirectors;
    }

    function tenureOfBoard() external view onlyUser returns (uint8) {
        return _ruleOfGovernance.tenureOfBoard;
    }

    function nominatorOfChairman() external view onlyUser returns (uint40) {
        return _ruleOfGovernance.nominatorOfChairman;
    }

    function nominatorOfViceChairman() external view onlyUser returns (uint40) {
        return _ruleOfGovernance.nominatorOfViceChairman;
    }

    function sumOfBoardSeatsQuota() external view onlyUser returns (uint8) {
        return _ruleOfGovernance.sumOfBoardSeatsQuota;
    }

    function boardSeatsQuotaOf(uint40 acct)
        external
        view
        onlyUser
        returns (uint8)
    {
        return _ruleOfGovernance.boardSeatsQuotaOf[acct];
    }
}
