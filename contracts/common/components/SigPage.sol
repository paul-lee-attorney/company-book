/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/DraftSetting.sol";

contract SigPage is DraftSetting {
    // 0-pending 1-finalized 2-signed
    uint8 public docState;

    uint public sigDeadline;

    uint public closingDeadline;

    mapping(address => bool) public isParty;
    uint8 public qtyOfParties;

    mapping(address => uint) public sigDate;
    address[] private _signers;

    //####################
    //##     event      ##
    //####################

    event UpdateStateOfDoc(uint8 state);

    event SetSigDeadline(uint deadline);

    event SetClosingDeadline(uint deadline);

    event AddParty(address acct);

    event RemoveParty(address acct);

    event SignDoc(address acct);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyForDraft() {
        require(docState == 0, "Doc NOT pending");
        _;
    }

    modifier onlyParty() {
        require(isParty[msg.sender], "msg.sender NOT Party");
        _;
    }

    modifier notSigned() {
        require(sigDate[msg.sender] == 0, "SIGNED already");
        _;
    }

    modifier onlyFutureTime(uint time) {
        require(time > now, "NOT FUTURE time");
        _;
    }

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyForDraft
    {
        sigDeadline = deadline;
        emit SetSigDeadline(deadline);
    }

    function setClosingDeadline(uint deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyForDraft
    {
        closingDeadline = deadline;
        emit SetClosingDeadline(deadline);
    }

    function addPartyToDoc(address acct) public onlyAttorney {
        if (!isParty[acct]) {
            isParty[acct] = true;
            qtyOfParties++;
            emit AddParty(acct);
        }
    }

    function removePartyFromDoc(address acct) external onlyAttorney {
        if (isParty[acct]) {
            delete isParty[acct];
            qtyOfParties--;
            emit RemoveParty(acct);
        }
    }

    function circulateDoc() external onlyAdmin onlyForDraft {
        docState = 1;
        lockContents();
        emit UpdateStateOfDoc(docState);
    }

    function signDoc() external onlyParty notSigned {
        require(docState == 1, "Doc NOT finalized");
        require(now < sigDeadline, "later than SigDeadline");
        address sender = msg.sender;
        sigDate[sender] = now;
        _signers.push(sender);
        emit SignDoc(sender);

        if (qtyOfParties == uint8(_signers.length)) {
            docState = 2;
            emit UpdateStateOfDoc(docState);
        }
    }

    function updateStateOfDoc(uint8 state) external onlyBookeeper {
        docState = state;
        emit UpdateStateOfDoc(docState);
    }

    function acceptDoc() external onlyParty notSigned {
        address sender = msg.sender;
        sigDate[sender] = now;
        _signers.push(sender);
        emit SignDoc(sender);
    }

    //####################
    //##    查询接口    ##
    //####################

    function signers() external view returns (address[]) {
        return _signers;
    }

    function isEstablished() external view returns (bool) {
        return docState == 2;
    }

    function signedBy(address acct) external view returns (bool) {
        return sigDate[acct] > 0;
    }
}
