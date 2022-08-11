/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IShareholdersAgreement.sol";
import "./terms/ITerm.sol";
import "../../common/access/IAccessControl.sol";
import "../../common/components/SigPage.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BOMSetting.sol";

import "../../common/utils/CloneFactory.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    BOMSetting,
    BOSSetting,
    SigPage
{
    using SNFactory for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // title => template address
    mapping(uint8 => address) private _tempOfTitle;

    // title => body
    mapping(uint8 => address) private _titleToBody;

    // titles
    EnumerableSet.UintSet private _titles;

    // bodys
    EnumerableSet.AddressSet private _bodies;

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
    bytes32[12] private _votingRules;

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

    Governance private _ruleOfGovernance;

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint8 title) {
        require(
            _titleToBody[title] != address(0),
            "SHA does not have such title"
        );
        _;
    }

    modifier tempReadyFor(uint8 title) {
        require(_tempOfTitle[title] != address(0), "Template NOT ready");
        _;
    }

    // ==== VotingRules ====
    modifier typeAllowed(uint8 typeOfVote) {
        require(typeOfVote < 12, "typeOfVote overflow");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[15] templates) external onlyManager(1) {
        for (uint8 i = 0; i < 15; i++) {
            _setTemplate(i, templates[i]);
        }
    }

    function _setTemplate(uint8 title, address tempAdd) private {
        if (
            title == uint8(EnumsRepo.TermTitle.LOCK_UP) ||
            title == uint8(EnumsRepo.TermTitle.ANTI_DILUTION) ||
            title == uint8(EnumsRepo.TermTitle.FIRST_REFUSAL) ||
            title == uint8(EnumsRepo.TermTitle.GROUPS_UPDATE) ||
            title == uint8(EnumsRepo.TermTitle.TAG_ALONG) ||
            title == uint8(EnumsRepo.TermTitle.DRAG_ALONG) ||
            title == uint8(EnumsRepo.TermTitle.OPTIONS)
        ) {
            _tempOfTitle[title] = tempAdd;

            emit SetTemplate(title, tempAdd);
        }
    }

    function createTerm(uint8 title)
        external
        onlyAttorney
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_tempOfTitle[title]);

        IAccessControl(body).init(
            getManagerKey(0),
            this,
            _rc,
            uint8(EnumsRepo.RoleOfUser.ShareholdersAgreement),
            _rc.entityNo(this)
        );

        IAccessControl(body).setManager(2, this);

        copyRoleTo(ATTORNEYS, body);
        copyRoleTo(KEEPERS, body);

        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setBOM(address(_bom));

        _titleToBody[title] = body;

        _titles.add(title);

        _bodies.add(body);

        emit CreateTerm(title, body, _msgSender());
    }

    function removeTerm(uint8 title) external onlyAttorney {
        _titles.remove(title);

        _bodies.remove(_titleToBody[title]);

        delete _titleToBody[title];

        emit RemoveTerm(title);
    }

    function finalizeSHA() external onlyManager(2) {
        address[] memory clauses = _bodies.values();
        uint256 len = clauses.length;

        while (len > 0) {
            IAccessControl(clauses[len - 1]).lockContents();
            len--;
        }

        finalizeDoc();
    }

    // ==== VotingRules ====

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

    function setAppointerOfChairman(uint40 nominator) external onlyAttorney {
        _ruleOfGovernance.appointerOfChairman = nominator;
        emit SetAppointerOfChairman(nominator);
    }

    function setAppointerOfViceChairman(uint40 nominator)
        external
        onlyAttorney
    {
        _ruleOfGovernance.appointerOfViceChairman = nominator;
        emit SetAppointerOfViceChairman(nominator);
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
    ) external onlyAttorney typeAllowed(typeOfVote) {
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

    function tempOfTitle(uint8 title) external view returns (address) {
        return _tempOfTitle[title];
    }

    function hasTitle(uint8 title) external view returns (bool) {
        return _titleToBody[title] != address(0);
    }

    function isTitle(uint8 title) external view returns (bool) {
        return _titles.contains(title);
    }

    function isBody(address addr) external view returns (bool) {
        return _bodies.contains(addr);
    }

    function titles() external view returns (uint8[]) {
        return _titles.valuesToUint8();
    }

    function bodies() external view returns (address[]) {
        return _bodies.values();
    }

    function getTerm(uint8 title)
        external
        view
        titleExist(title)
        returns (address body)
    {
        body = _titleToBody[title];
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_titleToBody[title]).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_titleToBody[title]).isExempted(ia, snOfDeal);
    }

    // ==== VotingRules ====

    function votingRules(uint8 typeOfVote) external view returns (bytes32) {
        return _votingRules[typeOfVote];
    }

    function basedOnPar() external view returns (bool) {
        return _ruleOfGovernance.basedOnPar;
    }

    function proposalThreshold() external view returns (uint16) {
        return _ruleOfGovernance.proposalThreshold;
    }

    function maxNumOfDirectors() external view returns (uint8) {
        return _ruleOfGovernance.maxNumOfDirectors;
    }

    function tenureOfBoard() external view returns (uint8) {
        return _ruleOfGovernance.tenureOfBoard;
    }

    function appointerOfChairman() external view returns (uint40) {
        return _ruleOfGovernance.appointerOfChairman;
    }

    function appointerOfViceChairman() external view returns (uint40) {
        return _ruleOfGovernance.appointerOfViceChairman;
    }

    function sumOfBoardSeatsQuota() external view returns (uint8) {
        return _ruleOfGovernance.sumOfBoardSeatsQuota;
    }

    function boardSeatsQuotaOf(uint40 acct) external view returns (uint8) {
        return _ruleOfGovernance.boardSeatsQuotaOf[acct];
    }
}
