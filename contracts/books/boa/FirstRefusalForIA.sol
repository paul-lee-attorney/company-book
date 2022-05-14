/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./AlongsForIA.sol";

contract FirstRefusalForIA is AlongsForIA {
    struct FRNotice {
        mapping(address => bool) isRequester;
        address[] requesters;
        bool basedOnPar;
        uint256 totalAmt;
    }

    // sequenceOfDeal => FRNotice
    mapping(uint16 => FRNotice) private _frNotices;

    // sequenceOfDeal => bool
    mapping(uint16 => bool) public isRequestedForFR;

    uint16[] private _frNoticesList;

    //##################
    //##    Event     ##
    //##################

    event RecordFRNotice(bytes32 indexed sn, address sender, uint32 execDate);

    event CreateFRDeal(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    );

    event AcceptFR(bytes32 indexed sn, address sender);

    //##################
    //##   Modifier   ##
    //##################

    modifier frNoticeExist(uint16 ssn) {
        require(isRequestedForFR[ssn], "NOT be requested for FR");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function recordFRRequest(
        uint16 ssn,
        address acct,
        bool basedOnPar,
        uint32 execDate
    ) external onlyKeeper dealExist(ssn) {
        FRNotice storage notice = _frNotices[ssn];
        Deal storage deal = _deals[ssn];

        require(
            deal.shareNumber.shareholder() != acct,
            "FR requester is seller"
        );
        require(!notice.isRequester[acct], "already recorded this notice");

        notice.isRequester[acct] = true;
        notice.requesters.push(acct);

        notice.basedOnPar = basedOnPar;

        uint256 weight = basedOnPar
            ? _bos.parInHand(acct)
            : _bos.paidInHand(acct);
        require(weight > 0, "first refusal request has ZERO weight");
        notice.totalAmt += weight;

        if (!isRequestedForFR[ssn]) {
            isRequestedForFR[ssn] = true;
            _frNoticesList.push(ssn);
            // removeSigOfParty(_deals[ssn].sn.buyerOfDeal());
            removeSigOfParty(_deals[ssn].shareNumber.shareholder());
        }

        if (!isParty[acct]) {
            addPartyToDoc(acct);
            addSigOfParty(acct, execDate);
        }

        updateStateOfDoc(1);

        emit RecordFRNotice(_deals[ssn].sn, acct, execDate);
    }

    function acceptFR(
        uint16 ssn,
        address acct,
        uint32 acceptDate
    ) external frNoticeExist(ssn) {
        FRNotice storage notice = _frNotices[ssn];
        Deal storage orgDeal = _deals[ssn];

        address[] memory requesters = notice.requesters;
        uint256 len = requesters.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 weight = notice.basedOnPar
                ? _bos.parInHand(requesters[i])
                : _bos.paidInHand(requesters[i]);

            counterOfDeals++;

            bytes32 snOfFR = _createSN(
                orgDeal.sn.typeOfDeal(),
                6, // FirstRefusal
                counterOfDeals,
                requesters[i],
                _bos.groupNo(requesters[i]),
                orgDeal.shareNumber
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
        }

        acceptDoc(acceptDate);

        emit AcceptFR(orgDeal.sn, acct);
    }

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function isRequester(uint16 ssn, address acct)
        external
        view
        frNoticeExist(ssn)
        returns (bool)
    {
        return _frNotices[ssn].isRequester[acct];
    }

    function requesters(uint16 ssn)
        external
        view
        frNoticeExist(ssn)
        returns (address[])
    {
        return _frNotices[ssn].requesters;
    }

    function frNoticesList() external view returns (uint16[]) {
        return _frNoticesList;
    }
}
