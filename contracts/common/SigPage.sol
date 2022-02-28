/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/DraftSetting.sol";

contract SigPage is DraftSetting {
    // 0-pending 1-finalized 2-signed
    uint8 private _docState;

    uint256 private _sigDeadline;

    uint256 private _closingDeadline;

    mapping(address => bool) private _isParty;
    uint8 private _qtyOfParties;

    mapping(address => uint256) private _sigDate;
    address[] private _signers;

    //####################
    //##     event      ##
    //####################

    event UpdateStateOfDoc(uint8 state);

    event SetSigDeadline(uint256 deadline);

    event SetClosingDeadline(uint256 deadline);

    event AddParty(address acct);

    event RemoveParty(address acct);

    event SignDoc(address acct);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyForDraft() {
        require(_docState == 0, "Doc NOT pending");
        _;
    }

    modifier onlyForFinalized() {
        require(_docState == 1, "Doc NOT finalized");
        _;
    }

    // modifier onlyForSigned() {
    //     require(_docState == 2, "Doc NOT signed");
    //     _;
    // }

    // modifier onlyForSigned() {
    //     require(_docState == 3, "Doc NOT submitted");
    //     _;
    // }

    modifier beforeSigDeadline() {
        require(now < _sigDeadline, "later than SigDeadline");
        _;
    }

    modifier beforeClosingDeadline() {
        require(now < _closingDeadline, "later than closingDeadline");
        _;
    }

    modifier onlyParty() {
        require(_isParty[msg.sender], "msg.sender NOT Party");
        _;
    }

    modifier onlyConcernedEntity() {
        address sender = msg.sender;
        require(
            _isParty[sender] ||
                sender == getAttorney() ||
                sender == getAdmin() ||
                sender == getBookeeper(),
            "NOT concerned Entity"
        );
        _;
    }

    modifier notSigned() {
        require(_sigDate[msg.sender] == 0, "SIGNED already");
        _;
    }

    modifier onlyFutureTime(uint256 time) {
        require(time > now, "NOT FUTURE time");
        _;
    }

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint256 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyForDraft
    {
        _sigDeadline = deadline;
        emit SetSigDeadline(deadline);
    }

    function setClosingDeadline(uint256 deadline)
        external
        onlyAttorney
        onlyFutureTime(deadline)
        onlyForDraft
    {
        _closingDeadline = deadline;
        emit SetClosingDeadline(deadline);
    }

    function addPartyToDoc(address acct) public onlyAttorney {
        if (!_isParty[acct]) {
            _isParty[acct] = true;
            _qtyOfParties++;
            emit AddParty(acct);
        }
    }

    function removePartyFromDoc(address acct) external onlyAttorney {
        if (_isParty[acct]) {
            delete _isParty[acct];
            _qtyOfParties--;
            emit RemoveParty(acct);
        }
    }

    function circulateDoc() external onlyAdmin onlyForDraft {
        _docState = 1;
        lockContents();
        emit UpdateStateOfDoc(_docState);
    }

    function signDoc()
        external
        onlyParty
        notSigned
        beforeSigDeadline
        onlyForFinalized
    {
        address sender = msg.sender;
        _sigDate[sender] = now;
        _signers.push(sender);
        emit SignDoc(sender);

        if (_qtyOfParties == uint8(_signers.length)) {
            _docState = 2;
            emit UpdateStateOfDoc(_docState);
        }
    }

    // function submitDoc() external onlyBookeeper onlyForSigned {
    //     _docState = 3;
    //     emit UpdateStateOfDoc(_docState);
    // }

    // function closeDoc(bool flag) public onlyBookeeper onlyForSigned {
    //     if (flag) {
    //         _docState = 4;
    //         emit UpdateStateOfDoc(this, _docState);
    //     } else if (now > _closingDeadline) {
    //         _docState = 5;
    //         emit UpdateStateOfDoc(this, _docState);
    //     }
    // }

    function updateStateOfDoc(uint8 state) external onlyBookeeper {
        _docState = state;
        emit UpdateStateOfDoc(_docState);
    }

    function acceptDoc() external onlyParty notSigned {
        address sender = msg.sender;
        _sigDate[sender] = now;
        _signers.push(sender);
        emit SignDoc(sender);
    }

    //####################
    //##    查询接口    ##
    //####################

    function isEstablished() external view onlyConcernedEntity returns (bool) {
        return _docState == 2;
    }

    function docState() external view onlyConcernedEntity returns (uint8) {
        return _docState;
    }

    function sigDeadline() external view onlyConcernedEntity returns (uint256) {
        return _sigDeadline;
    }

    function closingDeadline()
        public
        view
        returns (
            // onlyConcernedEntity
            uint256
        )
    {
        return _closingDeadline;
    }

    function isParty(address acct)
        external
        view
        returns (
            // onlyConcernedEntity
            bool
        )
    {
        return _isParty[acct];
    }

    function qtyOfParties() external view onlyConcernedEntity returns (uint8) {
        return _qtyOfParties;
    }

    function signedBy(address acct)
        external
        view
        onlyConcernedEntity
        returns (bool)
    {
        return _sigDate[acct] > 0;
    }

    function sigDate(address acct)
        external
        view
        onlyConcernedEntity
        returns (uint256)
    {
        return _sigDate[acct];
    }

    function signers() external view onlyConcernedEntity returns (address[]) {
        return _signers;
    }

    function qtyOfSigners()
        external
        view
        onlyConcernedEntity
        returns (uint256)
    {
        return _signers.length;
    }
}
