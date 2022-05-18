/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/UserGroup.sol";

import "../config/DraftControl.sol";

contract SigPage is DraftControl {
    using ArrayUtils for address[];
    using UserGroup for UserGroup.Group;

    // 0-pending 1-finalized 2-signed
    uint8 public docState;

    uint32 public sigDeadline;

    uint32 public closingDeadline;

    UserGroup.Group internal _docParties;

    // mapping(address => bool) public isParty;
    // uint8 public qtyOfParties;

    mapping(address => uint32) public sigDate;
    address[] private _signers;

    //####################
    //##     event      ##
    //####################

    event UpdateStateOfDoc(uint8 state);

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(address acct);

    event RemoveParty(address acct);

    event AddSigOfParty(address acct, uint32 sigDate);

    event RemoveSigOfParty(address acct);

    event SignDoc(address acct, uint32 sigDate);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyForDraft() {
        require(docState == 0, "Doc NOT pending");
        _;
    }

    modifier onlyParty() {
        require(_docParties.isMember(msg.sender), "msg.sender NOT a party");
        _;
    }

    modifier notSigned() {
        require(sigDate[msg.sender] == 0, "SIGNED already");
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

    function addPartyToDoc(address acct) public attorneyOrKeeper {
        if (_docParties.addMember(acct)) emit AddParty(acct);
    }

    function removePartyFromDoc(address acct) public attorneyOrKeeper {
        if (_docParties.removeMember(acct)) emit RemoveParty(acct);
    }

    function circulateDoc() external onlyGC onlyForDraft {
        require(
            primaryKey(OWNER) == address(0) && backupKey(OWNER) == address(0),
            "ownership not be abandoned"
        );

        docState = 1;

        abandonRole(ATTORNEYS);
        quitPosition(GENERAL_COUNSEL);

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
        address sender = msg.sender;
        sigDate[sender] = _sigDate;
        _signers.push(sender);
        emit SignDoc(sender, _sigDate);

        _checkCompletionOfSig();
    }

    function _checkCompletionOfSig() private {
        if (_docParties.qtyOfMembers() == uint8(_signers.length)) {
            docState = 2;
            emit UpdateStateOfDoc(docState);
        }
    }

    function updateStateOfDoc(uint8 state) public onlyKeeper {
        docState = state;
        emit UpdateStateOfDoc(docState);
    }

    function addSigOfParty(address acct, uint32 execDate) public onlyKeeper {
        sigDate[acct] = execDate;
        _signers.addValue(acct);
        emit AddSigOfParty(acct, execDate);
    }

    function removeSigOfParty(address acct) public onlyKeeper {
        // require(sigDate[acct] > 0, "party NOT signed");

        sigDate[acct] = 0;
        _signers.removeByValue(acct);

        emit RemoveSigOfParty(acct);
    }

    function acceptDoc(uint32 _sigDate)
        public
        onlyParty
        notSigned
        currentDate(_sigDate)
    {
        address sender = msg.sender;
        sigDate[sender] = _sigDate;
        _signers.push(sender);
        emit SignDoc(sender, _sigDate);

        _checkCompletionOfSig();
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
