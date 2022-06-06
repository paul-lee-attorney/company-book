/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/SignerGroup.sol";

import "../access/DraftControl.sol";

contract SigPage is DraftControl {
    using SignerGroup for SignerGroup.Group;

    bool public established;

    uint32 public sigDeadline;

    uint32 public closingDeadline;

    SignerGroup.Group internal _signatures;

    //####################
    //##     event      ##
    //####################

    event DocFinalized();

    event BackToFinalized();

    event DocEstablished();

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(uint32 acct);

    event RemoveParty(uint32 acct);

    event AddBlank(uint32 acct, uint16 sn);

    event SignDeal(uint32 acct, uint16 sn, uint32 sigDate, bytes32 sigHash);

    event SignDoc(uint32 acct, uint32 sigDate, bytes32 sigHash);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyParty() {
        require(_signatures.isParty(_msgSender()), "msg.sender NOT a party");
        _;
    }

    modifier onlyInitSigner() {
        require(_signatures.isInitSigner(_msgSender()), "not an InitSigner");
        _;
    }

    modifier notInitSigner() {
        require(!_signatures.isInitSigner(_msgSender()), "is an InitSigner");
        _;
    }

    modifier onlyFutureTime(uint32 date) {
        require(date > now + 15 minutes, "NOT FUTURE time");
        _;
    }

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint32 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyPending
    {
        sigDeadline = deadline;
        emit SetSigDeadline(deadline);
    }

    function setClosingDeadline(uint32 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyPending
    {
        closingDeadline = deadline;
        emit SetClosingDeadline(deadline);
    }

    function removePartyFromDoc(uint32 acct) public onlyPending onlyAttorney {
        if (_signatures.removeParty(acct)) emit RemoveParty(acct);
    }

    function circulateDoc() public onlyGC onlyPending {
        lockContents();
        finalized = true;
        emit DocFinalized();
    }

    function signDoc(uint32 sigDate, bytes32 sigHash)
        external
        onlyParty
        onlyFinalized
    {
        require(sigDate < sigDeadline, "later than SigDeadline");

        if (_signatures.signDeal(_msgSender(), 0, sigDate, sigHash))
            emit SignDoc(_msgSender(), sigDate, sigHash);
    }

    function acceptDoc(uint32 sigDate, bytes32 sigHash) external onlyParty {
        require(established, "Doc not established");

        if (_signatures.signDeal(_msgSender(), 0, sigDate, sigHash))
            emit SignDoc(_msgSender(), sigDate, sigHash);
    }

    function addBlank(uint32 acct, uint16 sn) public {
        if (!finalized)
            require(
                hasRole(ATTORNEYS, _msgSender()),
                "only Attorney may add party to a pending DOC"
            );
        else
            require(
                _msgSender() == getDirectKeeper(),
                "only DK may add party to an established DOC"
            );

        established = false;

        if (_signatures.addBlank(acct, sn)) emit AddBlank(acct, sn);
    }

    function signDeal(
        uint16 ssn,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) public onlyKeeper {
        if (_signatures.signDeal(caller, ssn, sigDate, sigHash)) {
            emit SignDeal(caller, ssn, sigDate, sigHash);
            _checkCompletionOfSig();
        }
    }

    function _checkCompletionOfSig() private {
        if (_signatures.docEstablished()) {
            established = true;
            emit DocEstablished();
        }
    }

    function backToFinalized(uint32 reviewDeadline) external onlyKeeper {
        if (established) established = false;
        sigDeadline = reviewDeadline;
        emit BackToFinalized();
    }

    //####################
    //##    查询接口    ##
    //####################

    function isParty(uint32 acct) public view returns (bool) {
        return _signatures.isParty(acct);
    }

    function isSigner(uint32 acct) external view returns (bool) {
        return _signatures.isSigner(acct);
    }

    function isInitSigner(uint32 acct) public view returns (bool) {
        return _signatures.isInitSigner(acct);
    }

    function parties() external view returns (uint32[]) {
        return _signatures.parties;
    }

    function qtyOfParties() external view returns (uint256) {
        return _signatures.parties.length;
    }

    function qtyOfBlankForParty(uint32 acct) external view returns (uint16) {
        return _signatures.counterOfBlank[acct];
    }

    function qtyOfSigForParty(uint32 acct) external view returns (uint16) {
        return _signatures.counterOfSig[acct];
    }

    function sigDateOfDeal(uint32 acct, uint16 sn)
        external
        view
        returns (uint32)
    {
        return _signatures.sigDateOfDeal(acct, sn);
    }

    function sigHashOfDeal(uint32 acct, uint16 sn)
        external
        view
        returns (bytes32)
    {
        return _signatures.sigHashOfDeal(acct, sn);
    }

    function sigDateOfDoc(uint32 acct)
        external
        view
        onlyInitSigner
        returns (uint32)
    {
        _signatures.sigDateOfDoc(acct);
    }

    function sigHashOfDoc(uint32 acct)
        external
        view
        onlyInitSigner
        returns (bytes32)
    {
        _signatures.sigHashOfDoc(acct);
    }

    function dealSigVerify(
        uint32 acct,
        uint16 sn,
        string src
    ) external view returns (bool) {
        return _signatures.dealSigVerify(acct, sn, src);
    }

    function partyDulySigned(uint32 acct) external view returns (bool) {
        return _signatures.partyDulySigned(acct);
    }
}
