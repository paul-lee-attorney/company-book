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

    bool public established;

    uint32 public sigDeadline;

    uint32 public closingDeadline;

    UserGroup.Group private _parties;

    SigList.List private _signatures;

    //####################
    //##     event      ##
    //####################

    event DocFinalized();

    event DocBackToPending();

    event DocEstablished();

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(uint32 acct);

    event RemoveParty(uint32 acct);

    event AddSigOfParty(uint32 acct, uint32 sigDate, bytes32 sigHash);

    event UpdateSigOfParty(uint32 acct, uint32 sigDate, bytes32 sigHash);

    // event RemoveSigOfParty(uint32 acct);

    event SignDoc(uint32 acct, uint32 sigDate, bytes32 sigHash);

    //####################
    //##    modifier    ##
    //####################

    // modifier onlyPending() {
    //     require(docState == 0, "Doc NOT pending");
    //     _;
    // }

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

    function addPartyToDoc(uint32 acct) public {
        if (!finalized)
            require(
                hasRole(ATTORNEYS, _msgSender()),
                "only Attorney may add party to a pending DOC"
            );
        else if (established)
            require(
                _msgSender() == getDirectKeeper(),
                "only DK may add party to an established DOC"
            );
        else revert("cannot add party to a DOC in signing stage");

        if (_parties.addMember(acct)) emit AddParty(acct);
    }

    function removePartyFromDoc(uint32 acct) public onlyPending onlyAttorney {
        if (_parties.removeMember(acct)) emit RemoveParty(acct);
    }

    function circulateDoc() public onlyGC onlyPending {
        lockContents();

        finalized = true;

        _parties.resetCounter();

        emit DocFinalized();
    }

    function signDoc(uint32 _sigDate, bytes32 _sigHash)
        external
        onlyFinalized
        notSigned
    {
        require(_sigDate < sigDeadline, "later than SigDeadline");

        _addSigOfParty(_msgSender(), _sigDate, _sigHash);
    }

    function acceptDoc(uint32 _sigDate, bytes32 _sigHash)
        public
        onlyParty
        notSigned
    {
        require(established, "Doc not established");

        _addSigOfParty(_msgSender(), _sigDate, _sigHash);
    }

    // function addSigOfParty(
    //     uint32 acct,
    //     uint32 _sigDate,
    //     bytes32 _sigHash
    // ) external onlyKeeper {
    //     _addSigOfParty(acct, _sigDate, _sigHash);
    // }

    function _addSigOfParty(
        uint32 acct,
        uint32 sigDate,
        bytes32 sigHash
    ) internal currentDate(sigDate) {
        require(_parties.isMember(acct), "not a Party");
        require(
            _parties.counterOfMember(acct) >= _signatures.counterOfSigner(acct),
            "not enough signing blank"
        );

        if (_signatures.addSignature(acct, sigDate, sigHash))
            emit AddSigOfParty(acct, sigDate, sigHash);
        else emit UpdateSigOfParty(acct, sigDate, sigHash);

        _checkCompletionOfSig();
    }

    function _checkCompletionOfSig() private {
        if (_parties.counterOfMembers() == _signatures.counterOfSigners()) {
            established = true;
            emit DocEstablished();
        }
    }

    //####################
    //##    查询接口    ##
    //####################

    function isParty(uint32 acct) public view returns (bool) {
        return _parties.isMember(acct);
    }

    function parties() external view returns (uint32[]) {
        return _parties.members();
    }

    function qtyOfParties() external view returns (uint256) {
        return _parties.qtyOfMembers();
    }

    function counterOfParty(uint32 acct) external view returns (uint16) {
        return _parties.counterOfMember(acct);
    }

    function counterOfParties() external view returns (uint16) {
        return _parties.counterOfMembers();
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

    function counterOfSigner(uint32 acct) external view returns (uint16) {
        return _signatures.counterOfSigner(acct);
    }

    function counterOfSigners() external view returns (uint16) {
        return _signatures.counterOfSigners();
    }

    function sigDate(uint32 acct) external view returns (uint32) {
        return _signatures.sigDate(acct);
    }

    function sigHash(uint32 acct) external view returns (bytes32) {
        return _signatures.sigHash(acct);
    }

    function sigVerify(uint32 acct, string src) external view returns (bool) {
        return _signatures.sigVerify(acct, src);
    }
}
