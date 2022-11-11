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

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";
import "../../common/ruting/BOMSetting.sol";

import "../../common/utils/CloneFactory.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    BOASetting,
    SHASetting,
    BOSSetting,
    ROMSetting,
    SigPage
{
    using SNParser for bytes32;

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

    struct Term {
        uint8 title;
        uint8 prev;
        uint8 next;
        address body;
    }

    /*
    terms[0] {
        title: qtyOfTerms;
        prev: tail;
        next: head;
        body: (null);
*/

    mapping(uint256 => Term) private _terms;

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

    // _boardSeatsOf[0]: sumOfBoardSeats;

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
        onlyManager(2)
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_boh.getTermTemplate(title));

        IAccessControl(body).init(
            getManagerKey(0),
            address(this),
            address(_rc),
            address(_gk)
        );

        IAccessControl(body).setManager(2, address(this), msg.sender);

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

        Term storage t = _terms[title];
        t.title = title;
        t.body = body;

        _increaseQtyOfTerms();

        uint8 tail = _terms[0].prev;

        t.prev = tail;
        _terms[tail].next = title;
        _terms[0].prev = title;

        emit CreateTerm(title, body, _msgSender());
    }

    function _increaseQtyOfTerms() private {
        _terms[0].title++;
    }

    function removeTerm(uint8 title) external onlyAttorney {
        Term storage t = _terms[title];

        _terms[t.prev].next = t.next;
        _terms[t.next].prev = t.prev;

        delete _terms[title];

        _decreaseQtyOfTerms();

        emit RemoveTerm(title);
    }

    function _decreaseQtyOfTerms() private {
        _terms[0].title--;
    }

    // ==== Rules ====
    function setGovernanceRule(bytes32 rule) external onlyAttorney {
        _rules[0] = rule;
        emit SetGovernanceRule(rule);
    }

    function setVotingRule(bytes32 rule) external onlyAttorney {
        require(rule.typeOfVoteOfVR() > 0, "SA.setVotingRule: ZERO typeOfVote");
        require(rule.votingDaysOfVR() > 0, "SA.setVotingRule: ZERO votingDays");
        _rules[rule.typeOfVoteOfVR()] = rule;
        emit SetVotingRule(rule.typeOfVoteOfVR(), rule);
    }

    function setBoardSeatsOf(uint40 nominator, uint8 quota)
        external
        onlyAttorney
    {
        require(nominator > 0, "SA.setBoardSeatsOf: zero nominator");

        uint8 orgQuota = _boardSeatsOf[nominator];

        if (orgQuota > 0) {
            require(
                _boardSeatsOf[0] - orgQuota + quota <= maxNumOfDirectors(),
                "board seats quota overflow"
            );
            _boardSeatsOf[0] -= orgQuota;
        } else {
            require(
                _boardSeatsOf[0] + quota <= maxNumOfDirectors(),
                "board seats quota overflow"
            );
        }

        _boardSeatsOf[nominator] = quota;
        _boardSeatsOf[0] += quota;

        emit SetBoardSeatsOf(nominator, quota);
    }

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) public view returns (bool) {
        return _terms[title].body > address(0);
    }

    function qtyOfTerms() public view returns (uint8 qty) {
        qty = _terms[0].title;
    }

    function titles() external view returns (uint8[] memory) {
        uint8[] memory list = new uint8[](qtyOfTerms());

        uint8 cur = _terms[0].next;
        uint256 i = 0;

        while (cur > 0) {
            list[i] = _terms[cur].title;
            cur = _terms[cur].next;
            i++;
        }

        return list;
    }

    function bodies() external view returns (address[] memory) {
        address[] memory list = new address[](qtyOfTerms());

        uint8 cur = _terms[0].next;
        uint256 i = 0;

        while (cur > 0) {
            list[i] = _terms[cur].body;
            cur = _terms[cur].next;
            i++;
        }

        return list;
    }

    function getTerm(uint8 title)
        external
        view
        titleExist(title)
        returns (address body)
    {
        body = _terms[title].body;
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_terms[title].body).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_terms[title].body).isExempted(ia, snOfDeal);
    }

    // ==== VotingRules ====

    function votingRules(uint8 typeOfVote) external view returns (bytes32) {
        require(typeOfVote > 0, "SA.votingRules: zero typeOfVote");
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

    function sumOfBoardSeats() external view returns (uint8) {
        return _boardSeatsOf[0];
    }

    function boardSeatsOf(uint40 acct) external view returns (uint8) {
        require(acct > 0, "SA.boardSeatsOf: zero acct");
        return _boardSeatsOf[acct];
    }
}
