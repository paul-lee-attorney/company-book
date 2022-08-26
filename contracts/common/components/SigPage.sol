/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/SNFactory.sol";
import "../lib/SNParser.sol";
import "../lib/EnumerableSet.sol";

import "../access/AccessControl.sol";

import "./ISigPage.sol";

contract SigPage is ISigPage, AccessControl {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bool private _established;

    uint32 private _sigDeadline;

    uint32 private _closingDeadline;

    struct Signature {
        uint32 blockNumber;
        uint32 sigDate;
        bytes32 sigHash;
    }

    mapping(bytes32 => Signature) private _signatures;

    EnumerableSet.Bytes32Set private _snList;

    uint256 private _sigCounter;

    EnumerableSet.UintSet private _parties;

    //####################
    //##    modifier    ##
    //####################

    modifier onlyParty() {
        require(isParty(_msgSender()), "_msgSender() NOT a party");
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
        require(uint256(date) > now + 15 minutes, "NOT FUTURE time");
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
        _sigDeadline = deadline;
        emit SetSigDeadline(deadline);
    }

    function setClosingDeadline(uint32 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyPending
    {
        _closingDeadline = deadline;
        emit SetClosingDeadline(deadline);
    }

    function finalizeDoc() public onlyManager(2) onlyPending {
        lockContents();
        _finalized = true;
        emit DocFinalized();
    }

    function signDoc(uint40 caller, bytes32 sigHash) public onlyFinalized {
        signDeal(0, caller, sigHash);
    }

    function acceptDoc(bytes32 sigHash) external onlyParty {
        require(_established, "Doc not established");
        signDeal(0, _msgSender(), sigHash);
    }

    function _createSN(uint40 acct, uint16 ssn) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);
        _sn = _sn.acctToSN(0, acct);
        _sn = _sn.sequenceToSN(5, ssn);

        return _sn.bytesToBytes32();
    }

    function addBlank(uint40 acct, uint16 ssn) public {
        if (!_finalized)
            require(
                _rc.hasRole(ATTORNEYS, msg.sender),
                "only Attorney may add party to a pending DOC"
            );
        else
            require(
                _rc.isKeeper(msg.sender),
                // _rc.hasRole(KEEPERS, msg.sender),
                "only DK may add party to an established DOC"
            );

        _established = false;

        bytes32 sn = _createSN(acct, ssn);

        if (_snList.add(sn)) {
            _parties.add(acct);
            emit AddBlank(acct, ssn);
        }
    }

    function removeBlank(uint40 acct, uint16 ssn)
        public
        onlyPending
        onlyAttorney
    {
        bytes32 sn = _createSN(acct, ssn);

        if (_snList.remove(sn)) {
            _parties.remove(acct);
            emit RemoveBlank(acct, ssn);
        }
    }

    function addParty(uint40 acct) external onlyPending onlyAttorney {
        addBlank(acct, 0);
    }

    function signDeal(
        uint16 ssn,
        uint40 caller,
        bytes32 sigHash
    ) public onlyKeeper {
        bytes32 sn = _createSN(caller, ssn);

        if (_snList.contains(sn) && _signatures[sn].sigDate == 0) {
            Signature storage sig = _signatures[sn];

            sig.blockNumber = uint32(block.number);
            sig.sigDate = uint32(block.timestamp);
            sig.sigHash = sigHash;

            _sigCounter++;

            emit SignDeal(caller, ssn, sigHash);

            _checkCompletionOfSig();
        }
    }

    function _checkCompletionOfSig() private {
        if (_sigCounter == _snList.length()) {
            _established = true;
            emit DocEstablished();
        }
    }

    //####################
    //##    查询接口    ##
    //####################

    function established() external view returns (bool) {
        return _established;
    }

    function sigDeadline() external view returns (uint32) {
        return _sigDeadline;
    }

    function closingDeadline() public view returns (uint32) {
        return _closingDeadline;
    }

    function isParty(uint40 acct) public view returns (bool) {
        return _parties.contains(acct);
    }

    function isInitSigner(uint40 acct) public view returns (bool) {
        return _snList.contains(bytes32(acct));
    }

    function parties() external view returns (uint40[]) {
        return _parties.valuesToUint40();
    }

    function qtyOfParties() external view returns (uint256) {
        return _parties.length();
    }

    function blanksList() external view returns (bytes32[]) {
        return _snList.values();
    }

    function sigCounter() external view returns (uint256) {
        return _sigCounter;
    }

    function sigDateOfDeal(uint40 acct, uint16 ssn)
        external
        view
        returns (uint32)
    {
        bytes32 sn = _createSN(acct, ssn);
        if (_snList.contains(sn)) return _signatures[sn].sigDate;
        else revert("the acct is not a party to the deal");
    }

    function sigHashOfDeal(uint40 acct, uint16 ssn)
        external
        view
        returns (bytes32)
    {
        bytes32 sn = _createSN(acct, ssn);
        if (_snList.contains(sn)) return _signatures[sn].sigHash;
        else revert("the acct is not a party to the deal");
    }

    function sigDateOfDoc(uint40 acct)
        external
        view
        onlyInitSigner
        returns (uint32)
    {
        return _signatures[bytes32(acct)].sigDate;
    }

    function sigHashOfDoc(uint40 acct)
        external
        view
        onlyInitSigner
        returns (bytes32)
    {
        return _signatures[bytes32(acct)].sigHash;
    }

    function dealSigVerify(
        uint40 acct,
        uint16 ssn,
        string src
    ) external view returns (bool) {
        bytes32 sn = _createSN(acct, ssn);
        return _signatures[sn].sigHash == keccak256(bytes(src));
    }
}
