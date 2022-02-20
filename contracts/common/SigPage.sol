/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/DraftSetting.sol";

contract SigPage is DraftSetting {
    // 0-pending 1-finalized 2-signed 3-submitted 4-closed 5-terminated
    uint8 private _docState;

    uint256 private _sigDeadline;

    uint256 private _closingStartpoint;

    uint256 private _closingDeadline;

    mapping(address => bool) private _isParty;
    uint8 private _qtyOfParties;

    mapping(address => uint256) private _sigDate;
    address[] private _signers;

    //####################
    //##     event      ##
    //####################

    event DocStateRevised(uint8 state);

    event SetSigDeadline(uint256 deadline);

    event SetClosingStartpoint(uint256 startpoint);

    event SetClosingDeadline(uint256 deadline);

    event AddParty(address acct);

    event RemoveParty(address acct);

    event SignDoc(address acct);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyForDraft() {
        require(_docState == 0, "Doc not pending");
        _;
    }

    modifier onlyForFinalized() {
        require(_docState == 1, "Doc not finalized");
        _;
    }

    modifier onlyForSigned() {
        require(_docState == 2, "Doc not signed");
        _;
    }

    modifier onlyForSubmitted() {
        require(_docState == 3, "Doc not submitted");
        _;
    }

    modifier beforeSigDeadline() {
        require(now < _sigDeadline, "later than SigDeadline");
        _;
    }

    modifier beforeClosingStartpoint() {
        require(now < _closingStartpoint, "later than closingStartpoint");
        _;
    }

    modifier beforeClosingDeadline() {
        require(now < _closingDeadline, "later than closingDeadline");
        _;
    }

    modifier onlyParty() {
        require(_isParty[msg.sender], "msg.sender not Party");
        _;
    }

    modifier beParty(address acct) {
        require(_isParty[acct], "acct not Party");
        _;
    }

    modifier onlyConcernedEntity() {
        address sender = msg.sender;
        require(
            _isParty[sender] ||
                sender == getAttorney() ||
                sender == getAdmin() ||
                sender == getBookeeper(),
            "msg.sender not interested Party"
        );
        _;
    }

    modifier notSigned() {
        require(_sigDate[msg.sender] == 0, "signed already");
        _;
    }

    modifier onlyFutureTime(uint256 time) {
        require(time > now, "not future time");
        _;
    }

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint256 deadline)
        external
        onlyAttorney
        onlyForDraft
        onlyFutureTime(deadline)
    {
        _sigDeadline = deadline;
        emit SetSigDeadline(deadline);
    }

    function setClosingStartpoint(uint256 startpoint)
        external
        onlyAttorney
        onlyForDraft
        onlyFutureTime(startpoint)
    {
        _closingStartpoint = startpoint;
        emit SetClosingStartpoint(startpoint);
    }

    function setClosingDeadline(uint256 deadline)
        external
        onlyAttorney
        onlyForDraft
        onlyFutureTime(deadline)
    {
        _closingDeadline = deadline;
        emit SetClosingDeadline(deadline);
    }

    function circulateDoc()
        internal
        onlyAttorney
        beforeClosingStartpoint
        onlyForDraft
    {
        _docState = 1;
        _lockContents();
        emit DocStateRevised(_docState);
    }

    function addPartyToDoc(address acct) internal onlyAttorney onlyForDraft {
        if (!_isParty[acct]) {
            _isParty[acct] = true;
            _qtyOfParties++;
            emit AddParty(acct);
        }
    }

    function removePartyFromDoc(address acct)
        internal
        onlyAttorney
        onlyForDraft
    {
        if (_isParty[acct]) {
            delete _isParty[acct];
            _qtyOfParties--;
            emit RemoveParty(acct);
        }
    }

    function signDoc()
        internal
        onlyParty
        notSigned
        onlyForFinalized
        beforeSigDeadline
    {
        address sender = msg.sender;
        _sigDate[sender] = now;
        _signers.push(sender);
        emit SignDoc(sender);

        if (_qtyOfParties == _signers.length) {
            _docState = 2;
            emit DocStateRevised(_docState);
        }
    }

    function submitDoc()
        external
        onlyBookeeper
        onlyForSigned
        beforeClosingStartpoint
    {
        _docState = 3;
        emit DocStateRevised(_docState);
    }

    // function closeDoc(bool flag) public onlyBookeeper onlyForSubmitted {
    //     if (flag) {
    //         _docState = 4;
    //         emit DocStateRevised(this, _docState);
    //     } else if (now > _closingDeadline) {
    //         _docState = 5;
    //         emit DocStateRevised(this, _docState);
    //     }
    // }

    function acceptDoc() internal onlyParty notSigned onlyForSubmitted {
        address sender = msg.sender;
        _sigDate[sender] = now;
        _signers.push(sender);
        emit SignDoc(sender);
    }

    //####################
    //##    查询接口    ##
    //####################

    function isEstablished() public onlyConcernedEntity returns (bool) {
        return _docState == 2;
    }

    function getDocState() public onlyConcernedEntity returns (uint8) {
        return _docState;
    }

    function getSigDeadline() public onlyConcernedEntity returns (uint256) {
        return _sigDeadline;
    }

    function getClosingStartpoint()
        public
        onlyConcernedEntity
        returns (uint256)
    {
        return _closingStartpoint;
    }

    function getClosingDeadline() public onlyConcernedEntity returns (uint256) {
        return _closingDeadline;
    }

    function isParty(address acct) public onlyConcernedEntity returns (bool) {
        return _isParty[acct];
    }

    function getQtyOfParties() public onlyConcernedEntity returns (uint8) {
        return _qtyOfParties;
    }

    function isSignedBy(address acct)
        public
        onlyConcernedEntity
        returns (bool)
    {
        return _sigDate[acct] > 0;
    }

    function getSigDate(address acct)
        public
        onlyConcernedEntity
        returns (uint256)
    {
        return _sigDate[acct];
    }

    function getSigners() public onlyConcernedEntity returns (address[]) {
        return _signers;
    }

    function getQtyOfSigners() public onlyConcernedEntity returns (uint256) {
        return _signers.length;
    }
}
