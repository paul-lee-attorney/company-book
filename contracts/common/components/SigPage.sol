/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/UserGroup.sol";
import "../../common/lib/SigList.sol";

import "../access/DraftControl.sol";

contract SigPage is DraftControl {
    using ArrayUtils for uint32[];
    using UserGroup for UserGroup.Group;
    using SigList for SigList.List;

    // 0-pending 1-finalized 2-signed
    uint8 public docState;

    uint32 public sigDeadline;

    uint32 public closingDeadline;

    UserGroup.Group internal _parties;

    SigList.List internal _signatures;

    //####################
    //##     event      ##
    //####################

    event UpdateStateOfDoc(uint8 state);

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(uint32 acct);

    event RemoveParty(uint32 acct);

    event AddSigOfParty(uint32 acct, uint32 sigDate);

    event RemoveSigOfParty(uint32 acct);

    event SignDoc(uint32 acct, uint32 sigDate);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyForDraft() {
        require(docState == 0, "Doc NOT pending");
        _;
    }

    modifier onlyParty() {
        require(_parties.isMember(_msgSender()), "msg.sender NOT a party");
        _;
    }

    modifier notSigned() {
        require(!_signatures.isSigner(_msgSender()), "SIGNED already");
        _;
    }

    modifier onlyFutureTime(uint32 time) {
        require(time > now + 15 minutes, "NOT FUTURE time");
        _;
    }

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint32 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyForDraft
    {
        sigDeadline = deadline;
        emit SetSigDeadline(deadline);
    }

    function setClosingDeadline(uint32 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyForDraft
    {
        closingDeadline = deadline;
        emit SetClosingDeadline(deadline);
    }

    function addPartyToDoc(uint32 acct) public attorneyOrKeeper {
        if (_parties.addMember(acct)) emit AddParty(acct);
    }

    function removePartyFromDoc(uint32 acct) public attorneyOrKeeper {
        if (_parties.removeMember(acct)) emit RemoveParty(acct);
    }

    function circulateDoc() external onlyGC onlyForDraft {
        require(getOwner() == 0, "ownership not be abandoned");

        docState = 1;

        lockContents();

        emit UpdateStateOfDoc(docState);
    }

    function signDoc(uint32 _sigDate)
        external
        onlyParty
        notSigned
        currentDate(_sigDate)
    {
        require(docState == 1, "Doc NOT finalized");
        require(_sigDate < sigDeadline, "later than SigDeadline");

        if (_signatures.addSignature(_msgSender(), _sigDate))
            emit SignDoc(_msgSender(), _sigDate);

        _checkCompletionOfSig();
    }

    function _checkCompletionOfSig() private {
        if (_parties.qtyOfMembers() == _signatures.qtyOfSigners()) {
            docState = 2;
            emit UpdateStateOfDoc(docState);
        }
    }

    function updateStateOfDoc(uint8 state) public onlyKeeper {
        docState = state;
        emit UpdateStateOfDoc(docState);
    }

    function addSigOfParty(uint32 acct, uint32 execDate) public onlyKeeper {
        if (_signatures.addSignature(acct, execDate))
            emit AddSigOfParty(acct, execDate);
    }

    function removeSigOfParty(uint32 acct) public onlyKeeper {
        if (_signatures.removeSignature(acct)) emit RemoveSigOfParty(acct);
    }

    function acceptDoc(uint32 sigDate)
        public
        onlyParty
        notSigned
        currentDate(sigDate)
    {
        require(docState > 1, "Doc not established");
        if (_signatures.addSignature(_msgSender(), sigDate))
            emit SignDoc(_msgSender(), sigDate);

        _checkCompletionOfSig();
    }

    //####################
    //##    查询接口    ##
    //####################

    function isEstablished() public view returns (bool) {
        return docState == 2;
    }

    function isParty(uint32 acct) public view returns (bool) {
        return _parties.isMember(acct);
    }

    function parties() external view returns (uint32[]) {
        return _parties.getMembers();
    }

    function qtyOfParties() external view returns (uint256) {
        return _parties.qtyOfMembers();
    }

    function isSigner(uint32 acct) external view returns (bool) {
        return _signatures.isSigner(acct);
    }

    function signers() external view returns (uint32[]) {
        return _signatures.signers();
    }

    function qtyOfSigners() external view returns (uint256) {
        return _signatures.qtyOfSigners();
    }

    function sigDate(uint32 acct) external view returns (uint32) {
        return _signatures.sigDate(acct);
    }
}
