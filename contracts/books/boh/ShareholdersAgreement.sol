// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "./terms/ITerm.sol";

import "../../common/access/IAccessControl.sol";
import "../../common/components/SigPage.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/EnumsRepo.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BOMSetting.sol";

import "../../common/utils/CloneFactory.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    SHASetting,
    BOMSetting,
    BOSSetting,
    SigPage
{
    using SNFactory for bytes;

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

    // typeOfVote => Rule: 1-CI 2-ST(to 3rd Party) 3-ST(to otherMember) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    mapping(uint256 => bytes32) private _votingRules;

    struct Governance {
        bool basedOnPar;
        uint16 proposalThreshold;
        uint8 maxNumOfDirectors;
        uint8 tenureOfBoard;
        uint40 appointerOfChairman;
        uint40 appointerOfViceChairman;
        uint8 sumOfBoardSeatsQuota;
        mapping(uint40 => uint8) boardSeatsQuotaOf;
    }

    Governance private _governanceRules;

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
        require(_boh.hasTemplate(title), "SHA.tempReadyFor: Template NOT ready");
        _;
    }

    // ==== VotingRules ====
    modifier typeAllowed(uint8 typeOfVote) {
        require(_votingRules[typeOfVote] > bytes32(0), "SHA.typeAllowed: typeOfVote overflow");
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
            uint8(EnumsRepo.RoleOfUser.SHATerms),
            _rc.entityNo(address(this))
        );

        IAccessControl(body).setManager(2, address(this), msg.sender);

        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setBOM(address(_bom));

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


    // function finalizeSHA() external onlyManager(2) {
    //     address[] memory clauses = _bodies.values();
    //     uint256 len = clauses.length;

    //     while (len > 0) {
    //         IAccessControl(clauses[len - 1]).lockContents();
    //         len--;
    //     }

    //     finalizeDoc();
    // }

    // ==== VotingRules ====

    function setVotingBaseOnPar(bool flag) external onlyAttorney {
        _governanceRules.basedOnPar = flag;
        emit SetVotingBaseOnPar(flag);
    }

    function setProposalThreshold(uint16 threshold) external onlyAttorney {
        _governanceRules.proposalThreshold = threshold;
        emit SetProposalThreshold(threshold);
    }

    function setMaxNumOfDirectors(uint8 num) external onlyAttorney {
        _governanceRules.maxNumOfDirectors = num;
        emit SetMaxNumOfDirectors(num);
    }

    function setTenureOfBoard(uint8 numOfYear) external onlyAttorney {
        _governanceRules.tenureOfBoard = numOfYear;
        emit SetTenureOfBoard(numOfYear);
    }

    function setAppointerOfChairman(uint40 nominator) external onlyAttorney {
        _governanceRules.appointerOfChairman = nominator;
        emit SetAppointerOfChairman(nominator);
    }

    function setAppointerOfViceChairman(uint40 nominator)
        external
        onlyAttorney
    {
        _governanceRules.appointerOfViceChairman = nominator;
        emit SetAppointerOfViceChairman(nominator);
    }

    function setBoardSeatsQuotaOf(uint40 nominator, uint8 quota)
        external
        onlyAttorney
    {
        uint8 orgQuota = uint8(_governanceRules.boardSeatsQuotaOf[nominator]);

        if (orgQuota > 0) {
            require(
                _governanceRules.sumOfBoardSeatsQuota - orgQuota + quota <=
                    _governanceRules.maxNumOfDirectors,
                "board seats quota overflow"
            );
            _governanceRules.sumOfBoardSeatsQuota -= orgQuota;
        } else {
            require(
                _governanceRules.sumOfBoardSeatsQuota + quota <=
                    _governanceRules.maxNumOfDirectors,
                "board seats quota overflow"
            );
        }

        _governanceRules.boardSeatsQuotaOf[nominator] = quota;
        _governanceRules.sumOfBoardSeatsQuota += quota;

        emit SetBoardSeatsQuotaOf(nominator, quota);
    }

    function setRule(
        uint8 typeOfVote,
        uint40 vetoHolder,
        uint16 ratioHead,
        uint16 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool partyAsConsent,
        bool againstShallBuy,
        uint8 reviewDays,
        uint8 votingDays,
        uint8 execDaysForPutOpt
    ) external onlyAttorney {
        require(votingDays > 0, "ZERO votingDays");

        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, ratioHead);
        _sn = _sn.sequenceToSN(2, ratioAmount);
        _sn = _sn.boolToSN(4, onlyAttendance);
        _sn = _sn.boolToSN(5, impliedConsent);
        _sn = _sn.boolToSN(6, partyAsConsent);
        _sn = _sn.boolToSN(7, againstShallBuy);
        _sn[8] = bytes1(reviewDays);
        _sn[9] = bytes1(votingDays);
        _sn[10] = bytes1(execDaysForPutOpt);
        _sn[11] = bytes1(typeOfVote);
        _sn = _sn.acctToSN(12, vetoHolder);

        _votingRules[typeOfVote] = _sn.bytesToBytes32();

        emit SetRule(typeOfVote, _votingRules[typeOfVote]);
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
        uint i=0;

        while(cur > 0) {
            list[i]=_terms[cur].title;
            cur = _terms[cur].next;
            i++;
        }

        return list;
    }

    function bodies() external view returns (address[] memory) {

        address[] memory list = new address[](qtyOfTerms());

        uint8 cur = _terms[0].next;
        uint i=0;

        while(cur > 0) {
            list[i]=_terms[cur].body;
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
        return _votingRules[typeOfVote];
    }

    function basedOnPar() external view returns (bool) {
        return _governanceRules.basedOnPar;
    }

    function proposalThreshold() external view returns (uint16) {
        return _governanceRules.proposalThreshold;
    }

    function maxNumOfDirectors() external view returns (uint8) {
        return _governanceRules.maxNumOfDirectors;
    }

    function tenureOfBoard() external view returns (uint8) {
        return _governanceRules.tenureOfBoard;
    }

    function appointerOfChairman() external view returns (uint40) {
        return _governanceRules.appointerOfChairman;
    }

    function appointerOfViceChairman() external view returns (uint40) {
        return _governanceRules.appointerOfViceChairman;
    }

    function sumOfBoardSeatsQuota() external view returns (uint8) {
        return _governanceRules.sumOfBoardSeatsQuota;
    }

    function boardSeatsQuotaOf(uint40 acct) external view returns (uint8) {
        return _governanceRules.boardSeatsQuotaOf[acct];
    }
}
