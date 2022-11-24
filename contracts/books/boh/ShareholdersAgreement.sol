// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "./terms/ITerm.sol";

import "../../books/boh/BookOfSHA.sol";

import "../../common/access/IAccessControl.sol";
import "../../common/components/SigPage.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/BOHSetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/utils/CloneFactory.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    BOASetting,
    BOHSetting,
    BOSSetting,
    ROMSetting,
    SigPage
{
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TermTitle {
        ZeroPoint, //            0
        LOCK_UP, //              1
        ANTI_DILUTION, //        2
        FIRST_REFUSAL, //        3
        GROUPS_UPDATE, //        4
        DRAG_ALONG, //           5
        TAG_ALONG, //            6
        OPTIONS //               7
    }

    // title => body
    mapping(uint256 => address) private _terms;

    EnumerableSet.UintSet private _titles;

    // ==== VotingRules ========

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
    //     uint40 vetoHolder;
    // }

    // _rules[0]: GovernanceRule {
    //     bool basedOnPar;
    //     uint16 proposalThreshold;
    //     uint8 maxNumOfDirectors;
    //     uint8 tenureOfBoard;
    //     uint40 appointerOfChairman;
    //     uint40 appointerOfViceChairman;
    // }

    // typeOfVote => Rule: 1-CI 2-ST(to 3rd Party) 3-ST(to otherMember) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    mapping(uint256 => bytes32) private _rules;

    // userNo => qty of directors can be appointed/nominated by the member;
    mapping(uint256 => uint8) private _boardSeatsOf;

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint8 title) {
        require(
            hasTitle(title),
            "SHA.titleExist: SHA does not have such title"
        );
        _;
    }

    modifier tempReadyFor(uint8 title) {
        require(
            _boh.hasTemplate(title),
            "SHA.tempReadyFor: Template NOT ready"
        );
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function createTerm(uint8 title)
        external
        onlyManager(1)
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_boh.getTermTemplate(title));

        uint40 owner = getManager(0);

        uint40 gc = getManager(1);

        IAccessControl(body).init(
            owner,
            address(this),
            address(_rc),
            address(_gk)
        );

        IAccessControl(body).setManager(1, gc);

        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.LOCK_UP) ||
            title == uint8(TermTitle.FIRST_REFUSAL) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setBOS(address(_bos));

        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setBOS(address(_bos));

        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.FIRST_REFUSAL) ||
            title == uint8(TermTitle.GROUPS_UPDATE) ||
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setROM(address(_rom));

        if (
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setBOA(address(_boa));

        _terms[title] = body;
        _titles.add(title);

        emit CreateTerm(title, body);
    }

    function removeTerm(uint8 title) external onlyAttorney {
        if (_titles.remove(title)) {
            delete _terms[title];
            emit RemoveTerm(title);
        }
    }

    function finalizeTerms() external onlyDK {
        uint256 len = _titles.length();

        for (uint256 i = 0; i < len; i++) {
            IAccessControl(_terms[_titles.at(i)]).lockContents();
        }

        lockContents();
    }

    // ==== Rules ====
    function setGovernanceRule(bytes32 rule) external onlyAttorney {
        _rules[0] = rule;
        emit SetGovernanceRule(rule);
    }

    function setVotingRule(bytes32 rule) external onlyAttorney {
        require(
            rule.typeOfVoteOfVR() != 0,
            "SA.setVotingRule: ZERO typeOfVote"
        );
        require(
            rule.votingDaysOfVR() != 0,
            "SA.setVotingRule: ZERO votingDays"
        );

        _rules[rule.typeOfVoteOfVR()] = rule;

        emit SetVotingRule(rule.typeOfVoteOfVR(), rule);
    }

    function setBoardSeatsOf(uint40 nominator, uint8 quota)
        external
        onlyAttorney
    {
        _boardSeatsOf[nominator] = quota;

        emit SetBoardSeatsOf(nominator, quota);
    }

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) public view returns (bool) {
        return _titles.contains(title);
    }

    function qtyOfTerms() public view returns (uint8) {
        return uint8(_titles.length());
    }

    function titles() external view returns (uint8[] memory) {
        return _titles.valuesToUint8();
    }

    function bodies() external view returns (address[] memory) {
        uint256 len = _titles.length();

        address[] memory list = new address[](len);

        while (len != 0) {
            list[len - 1] = _terms[_titles.at(len - 1)];
            len--;
        }

        return list;
    }

    function getTerm(uint8 title) external view returns (address) {
        return _terms[title];
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_terms[title]).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_terms[title]).isExempted(ia, snOfDeal);
    }

    // ==== VotingRules ====

    function votingRules(uint8 typeOfVote) external view returns (bytes32) {
        require(typeOfVote != 0, "SA.votingRules: zero typeOfVote");
        return _rules[typeOfVote];
    }

    function basedOnPar() external view returns (bool) {
        return uint8(_rules[0][0]) == 1;
    }

    function proposalThreshold() external view returns (uint16) {
        return uint16(bytes2(_rules[0] << 8));
    }

    function maxNumOfDirectors() public view returns (uint8) {
        return uint8(_rules[0][3]);
    }

    function tenureOfBoard() external view returns (uint8) {
        return uint8(_rules[0][4]);
    }

    function appointerOfChairman() external view returns (uint40) {
        return uint40(bytes5(_rules[0] << 40));
    }

    function appointerOfViceChairman() external view returns (uint40) {
        return uint40(bytes5(_rules[0] << 80));
    }

    function boardSeatsOf(uint40 acct) external view returns (uint8) {
        return _boardSeatsOf[acct];
    }
}
