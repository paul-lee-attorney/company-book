/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./InvestmentAgreement.sol";

import "../../common/lib/UserGroup.sol";
import "../../common/lib/SequenceList.sol";

contract InvestmentAgreementWithFirstRefusal is InvestmentAgreement {
    using UserGroup for UserGroup.Group;
    using SequenceList for SequenceList.List;

    struct FRNotice {
        UserGroup.Group execParties;
        bool basedOnPar;
        uint256 totalAmt;
    }

    // sequenceOfDeal => FRNotice
    mapping(uint16 => FRNotice) private _frNotices;

    // sequenceOfDeal => bool/list
    SequenceList.List internal _subjectDeals;

    //##################
    //##    Event     ##
    //##################

    event RecordFRNotice(bytes32 indexed sn, uint32 sender, uint32 execDate);

    event CreateFRDeal(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    );

    event AcceptFR(bytes32 indexed sn, uint32 sender);

    //##################
    //##   Modifier   ##
    //##################

    modifier subDealExist(uint16 ssn) {
        require(_subjectDeals.isItem(ssn), "NOT be requested for FR");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function recordFRRequest(
        uint16 ssn,
        bool basedOnPar,
        uint32 acct,
        uint32 execDate,
        bytes32 sigHash
    ) external onlyKeeper dealExist(ssn) {
        FRNotice storage notice = _frNotices[ssn];
        Deal storage deal = _deals[ssn];

        require(
            deal.shareNumber.shareholder() != acct,
            "FR requester is seller"
        );

        require(
            notice.execParties.addMember(acct),
            "already record the FR notice"
        );

        notice.basedOnPar = basedOnPar;

        uint256 weight = basedOnPar
            ? _bos.parInHand(acct)
            : _bos.paidInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");
        notice.totalAmt += weight;

        // request seller to check and confirm
        _subjectDeals.addItem(ssn);

        _signatures.addBlank(acct, 0);
        _signatures.signDeal(acct, 0, execDate, sigHash);

        established = false;

        emit RecordFRNotice(_deals[ssn].sn, acct, execDate);
    }

    function acceptFR(
        uint16 ssn,
        uint32 acct,
        uint32 acceptDate,
        bytes32 sigHash
    ) external subDealExist(ssn) {
        FRNotice storage notice = _frNotices[ssn];
        Deal storage orgDeal = _deals[ssn];

        uint32[] memory parties = notice.execParties.members();
        uint256 len = parties.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 weight = notice.basedOnPar
                ? _bos.parInHand(parties[i])
                : _bos.paidInHand(parties[i]);

            counterOfDeals++;

            bytes32 snOfFR = _createSN(
                orgDeal.sn.typeOfDeal(),
                6, // FirstRefusal
                counterOfDeals,
                parties[i],
                _bos.groupNo(parties[i]),
                orgDeal.shareNumber,
                orgDeal.sn.sequenceOfDeal()
            );

            Deal storage frDeal = _deals[counterOfDeals];

            frDeal.sn = snOfFR;
            frDeal.shareNumber = orgDeal.shareNumber;
            frDeal.unitPrice = orgDeal.unitPrice;
            frDeal.parValue = (orgDeal.parValue * weight) / notice.totalAmt;
            frDeal.paidPar = (orgDeal.paidPar * weight) / notice.totalAmt;
            frDeal.closingDate = orgDeal.closingDate;

            emit CreateFRDeal(
                snOfFR,
                frDeal.shareNumber,
                frDeal.unitPrice,
                frDeal.parValue,
                frDeal.paidPar,
                frDeal.closingDate
            );

            _signatures.addBlank(acct, counterOfDeals);
            _signatures.signDeal(acct, counterOfDeals, acceptDate, sigHash);
        }

        emit AcceptFR(orgDeal.sn, acct);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function isExecParty(uint16 ssn, uint32 acct)
        external
        view
        subDealExist(ssn)
        returns (bool)
    {
        return _frNotices[ssn].execParties.isMember(acct);
    }

    function execParties(uint16 ssn)
        external
        view
        subDealExist(ssn)
        returns (uint32[])
    {
        return _frNotices[ssn].execParties.members();
    }

    function isSubjectDeal(uint16 ssn) external view returns (bool) {
        return _subjectDeals.isItem(ssn);
    }

    function subjectDeals() external view returns (uint16[]) {
        return _subjectDeals.getItems();
    }
}
