/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/ObjGroup.sol";

import "../access/DraftControl.sol";

contract SigPage is DraftControl {
    using ObjGroup for ObjGroup.SignerGroup;

    bool public established;

    uint32 public sigDeadline;

    uint32 public closingDeadline;

    ObjGroup.SignerGroup private _signatures;

    //####################
    //##     event      ##
    //####################

    event DocFinalized();

    event BackToFinalized();

    event DocEstablished();

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(uint40 acct);

    event RemoveParty(uint40 acct);

    event AddBlank(uint40 acct, uint16 sn);

    event SignDeal(uint40 acct, uint16 sn, uint32 sigDate, bytes32 sigHash);

    event SignDoc(uint40 acct, uint32 sigDate, bytes32 sigHash);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyParty() {
        require(isParty(_msgSender()), "msg.sender NOT a party");
        _;
    }

    modifier onlyInitSigner() {
        require(isInitSigner(_msgSender()), "not an InitSigner");
        _;
    }

    modifier notInitSigner() {
        require(!isInitSigner(_msgSender()), "is an InitSigner");
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

    function removePartyFromDoc(uint40 acct) public onlyPending onlyAttorney {
        if (_signatures.removeParty(acct)) emit RemoveParty(acct);
    }

    function finalizeDoc() public onlyGC onlyPending {
        lockContents();
        finalized = true;
        emit DocFinalized();
    }

    function signDoc(
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) public onlyFinalized {
        require(sigDate < sigDeadline, "later than SigDeadline");

        if (_signatures.signDeal(caller, 0, sigDate, sigHash)) {
            emit SignDoc(caller, sigDate, sigHash);
            _checkCompletionOfSig();
        }
    }

    function acceptDoc(uint32 sigDate, bytes32 sigHash) external onlyParty {
        require(established, "Doc not established");

        if (_signatures.signDeal(_msgSender(), 0, sigDate, sigHash)) {
            emit SignDoc(_msgSender(), sigDate, sigHash);
            _checkCompletionOfSig();
        }
    }

    function addBlank(uint40 acct, uint16 ssn) public {
        if (!finalized)
            require(
                hasRole(ATTORNEYS, _msgSender()),
                "only Attorney may add party to a pending DOC"
            );
        else
            require(
                hasRole(KEEPERS, _msgSender()),
                "only DK may add party to an established DOC"
            );

        established = false;

        if (_signatures.addBlank(acct, ssn)) emit AddBlank(acct, ssn);
    }

    function signDeal(
        uint16 ssn,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) public onlyKeeper {
        if (_signatures.signDeal(caller, ssn, sigDate, sigHash)) {
            emit SignDeal(caller, ssn, sigDate, sigHash);
            _checkCompletionOfSig();
        }
    }

    function _checkCompletionOfSig() private {
        if (_signatures.balance == 0) {
            established = true;
            emit DocEstablished();
        }
    }

    // function backToFinalized(uint32 reviewDeadline) external onlyKeeper {
    //     if (established) established = false;
    //     sigDeadline = reviewDeadline;
    //     emit BackToFinalized();
    // }

    //####################
    //##    查询接口    ##
    //####################

    function isParty(uint40 acct) public view returns (bool) {
        return _signatures.counterOfBlank[acct] > 0;
    }

    function isSigner(uint40 acct) external view returns (bool) {
        return _signatures.counterOfSig[acct] > 0;
    }

    function isInitSigner(uint40 acct) public view returns (bool) {
        return _signatures.sigDate[acct][0] > 0;
    }

    function parties() external view returns (uint40[]) {
        return _signatures.parties;
    }

    function qtyOfParties() external view returns (uint256) {
        return _signatures.parties.length;
    }

    function qtyOfBlankForParty(uint40 acct) external view returns (uint16) {
        return _signatures.counterOfBlank[acct];
    }

    function qtyOfSigForParty(uint40 acct) external view returns (uint16) {
        return _signatures.counterOfSig[acct];
    }

    function sigDateOfDeal(uint40 acct, uint16 sn)
        external
        view
        returns (uint32)
    {
        uint16 seq = _signatures.dealToSN[acct][sn];
        if (seq > 0) return _signatures.sigDate[acct][seq];
        else revert("party did not sign this deal");
    }

    function sigHashOfDeal(uint40 acct, uint16 sn)
        external
        view
        returns (bytes32)
    {
        uint16 seq = _signatures.dealToSN[acct][sn];
        if (seq > 0) return _signatures.sigHash[acct][seq];
        else revert("party did not sign this deal");
    }

    function sigDateOfDoc(uint40 acct)
        external
        view
        onlyInitSigner
        returns (uint32)
    {
        return _signatures.sigDate[acct][0];
    }

    function sigHashOfDoc(uint40 acct)
        external
        view
        onlyInitSigner
        returns (bytes32)
    {
        return _signatures.sigHash[acct][0];
    }

    function dealSigVerify(
        uint40 acct,
        uint16 sn,
        string src
    ) external view returns (bool) {
        uint16 seq = _signatures.dealToSN[acct][sn];
        return _signatures.sigHash[acct][seq] == keccak256(bytes(src));
    }

    function partyDulySigned(uint40 acct) external view returns (bool) {
        return
            _signatures.counterOfBlank[acct] == _signatures.counterOfSig[acct];
    }
}
