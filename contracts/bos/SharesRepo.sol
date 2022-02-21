/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "../config/AdminSetting.sol";

contract SharesRepo is AdminSetting {
    using SafeMath for uint256;
    using ArrayUtils for uint256[];
    using ArrayUtils for address[];

    //Share 股票
    struct Share {
        uint256 shareNumber; //出资证明书编号（股票编号）
        address shareholder; //股东地址
        uint8 class; //股份类别（投资轮次）
        uint256 parValue; //票面金额（注册资本面值）
        uint256 paidInDeadline; //出资期限（时间戳）
        uint256 issueDate; //发行日期（时间戳）
        uint256 issuePrice; //发行价格（最小单位为分）
        uint256 obtainedDate; //取得日期（时间戳）
        uint256 obtainedPrice; //获取价格
        uint256 paidInDate; //实缴日期
        uint256 paidInAmount; //实缴金额
        uint8 state; //股票状态
    }

    //注册资本总额
    uint256 private _regCap;

    //实缴出资总额
    uint256 private _paidInCap;

    //shareNumber => Share
    mapping(uint256 => Share) private _shares;

    //shareNumber => exist?
    mapping(uint256 => bool) private _isShareNum;

    //股票编号数组
    uint256[] private _shareList;

    //股份类别 => 股东地址
    mapping(uint8 => address[]) private _membersOfClass;

    //股份类别 => 股份编号
    mapping(uint8 => uint256[]) private _sharesOfClass;

    //##################
    //##    Event     ##
    //##################

    event IssueShare(
        uint256 indexed shareNumber,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 qtyOfShares
    );

    event PayInCapital(
        uint256 indexed shareNumber,
        uint256 amount,
        uint256 paidInDate
    );

    event SubAmountFromShare(
        uint256 indexed shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    );

    event CapIncrease(
        uint256 parValue,
        uint256 regCap,
        uint256 paidInAmount,
        uint256 paiInCap
    );

    event CapDecrease(
        uint256 parValue,
        uint256 regCap,
        uint256 paidInAmount,
        uint256 paidInCap
    );

    event DeregisterShare(uint256 indexed shareNumber, uint256 qtyOfShares);

    event UpdateShareState(uint256 indexed shareNumber, uint8 state);

    event UpdatePaidInDeadline(
        uint256 indexed shareNumber,
        uint256 paidInDeadline
    );

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyNormalState(uint256 shareNumber) {
        require(_shares[shareNumber].state == 0, "state of Share ABNORMAL");
        _;
    }

    modifier numberNotZero(uint256 number) {
        require(number != 0, "number is Zero");
        _;
    }

    modifier shareNumberNotUsed(uint256 shareNumber) {
        require(!_isShareNum[shareNumber], "shareNumber has been used");
        _;
    }

    modifier onlyExistShare(uint256 shareNumber) {
        require(_isShareNum[shareNumber], "shareNumber NOT exist");
        _;
    }

    modifier addressNotZero(address acct) {
        require(acct != address(0), "acct address is Zero");
        _;
    }

    modifier onlyPastTime(uint256 time) {
        require(time <= now + 2 hours, "NOT past time");
        _;
    }

    modifier notLaterThan(uint256 date1, uint256 date2) {
        require(date1 <= date2, "date1 LATER than date2");
        _;
    }

    modifier laterOrZero(uint256 date1, uint256 date2) {
        require(
            date2 == 0 || date1 <= date2,
            "date2 EARLY than date1 but NOT Zero"
        );
        _;
    }

    modifier notBiggerThan(uint256 amount1, uint256 amount2) {
        require(amount1 <= amount2, "amount1 BIGGER than amount2");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _issueShare(
        uint256 shareNumber,
        address shareholder,
        uint8 class,
        uint256 parValue,
        uint256 paidInDeadline,
        uint256 issueDate,
        uint256 issuePrice,
        uint256 obtainedDate,
        uint256 obtainedPrice,
        uint256 paidInDate,
        uint256 paidInAmount,
        uint8 state
    )
        internal
        onlyBookeeper
        numberNotZero(shareNumber)
        shareNumberNotUsed(shareNumber)
        addressNotZero(shareholder)
        onlyPastTime(issueDate)
        notLaterThan(issueDate, paidInDeadline)
        notLaterThan(paidInDate, paidInDeadline)
        laterOrZero(issueDate, obtainedDate)
        laterOrZero(issueDate, paidInDate)
        notBiggerThan(paidInAmount, parValue)
    {
        Share storage share = _shares[shareNumber];

        share.shareNumber = shareNumber;
        share.shareholder = shareholder;
        share.class = class;
        share.parValue = parValue;
        share.paidInDeadline = paidInDeadline;
        share.issueDate = issueDate > 0 ? issueDate : now;
        share.issuePrice = issuePrice > 0 ? issuePrice : 1;
        share.obtainedDate = obtainedDate > 0 ? obtainedDate : issueDate;
        share.obtainedPrice = obtainedPrice > 0 ? obtainedPrice : issuePrice;
        share.paidInDate = paidInDate > 0 ? paidInDate : 0;
        share.paidInAmount = paidInAmount > 0 ? paidInAmount : 0;
        share.state = state > 0 ? state : 0;

        _isShareNum[shareNumber] = true;
        _shareList.push(shareNumber);

        _membersOfClass[class].addValue(shareholder);
        _sharesOfClass[class].push(shareNumber);

        emit IssueShare(shareNumber, parValue, paidInAmount, _shareList.length);
    }

    function _splitShare(
        uint256 shareNumber,
        uint256 newShareNumber,
        address newShareholder,
        uint256 parValue,
        uint256 splitDate,
        uint256 transferPrice,
        uint256 paidInAmount
    )
        internal
        onlyBookeeper
        numberNotZero(newShareNumber)
        shareNumberNotUsed(newShareNumber)
        addressNotZero(newShareholder)
        onlyPastTime(splitDate)
        laterOrZero(_shares[shareNumber].issueDate, splitDate)
        notBiggerThan(paidInAmount, parValue)
    {
        Share storage share = _shares[shareNumber];

        Share storage newShare = _shares[newShareNumber];

        newShare.shareNumber = newShareNumber;
        newShare.shareholder = newShareholder;
        newShare.class = share.class;
        newShare.parValue = parValue;
        newShare.paidInDeadline = share.paidInDeadline;
        newShare.issueDate = share.issueDate;
        newShare.issuePrice = share.issuePrice;
        newShare.obtainedDate = splitDate > 0 ? splitDate : now;
        newShare.obtainedPrice = transferPrice;
        newShare.paidInDate = share.paidInDate;
        newShare.paidInAmount = paidInAmount;
        newShare.state = share.state;

        _isShareNum[newShareNumber] = true;
        _shareList.push(newShareNumber);

        _membersOfClass[share.class].addValue(newShareholder);
        _sharesOfClass[share.class].push(newShareNumber);

        emit IssueShare(
            newShareNumber,
            parValue,
            paidInAmount,
            _shareList.length
        );
    }

    function _deregisterShare(uint256 shareNumber) internal onlyBookeeper {
        uint8 class = _shares[shareNumber].class;
        address shareholder = _shares[shareNumber].shareholder;

        _sharesOfClass[class].removeByValue(shareNumber);

        bool flag;

        for (uint8 i = 0; i < _sharesOfClass[class].length; i++) {
            if (_shares[_sharesOfClass[class][i]].shareholder == shareholder) {
                flag = true;
                break;
            }
        }

        if (!flag) _membersOfClass[class].removeByValue(shareholder);

        delete _shares[shareNumber];
        _shareList.removeByValue(shareNumber);
        _isShareNum[shareNumber] = false;

        emit DeregisterShare(shareNumber, _shareList.length);
    }

    function _payInCapital(
        uint256 shareNumber,
        uint256 amount,
        uint256 paidInDate
    )
        internal
        onlyBookeeper
        onlyPastTime(paidInDate)
        notLaterThan(paidInDate, _shares[shareNumber].paidInDeadline)
        notBiggerThan(
            _shares[shareNumber].paidInAmount.add(amount),
            _shares[shareNumber].parValue
        )
    {
        Share storage share = _shares[shareNumber];

        share.paidInAmount += amount; //溢出校验已通过
        share.paidInDate = paidInDate > 0 ? paidInDate : now;

        emit PayInCapital(shareNumber, amount, share.paidInDate);
    }

    function _subAmountFromShare(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    )
        internal
        onlyBookeeper
        notBiggerThan(paidInAmount, parValue)
        notBiggerThan(paidInAmount, _shares[shareNumber].paidInAmount)
    {
        Share storage share = _shares[shareNumber];

        share.parValue -= parValue;
        share.paidInAmount -= paidInAmount;

        emit SubAmountFromShare(shareNumber, parValue, paidInAmount);
    }

    function _capIncrease(uint256 parValue, uint256 paidInAmount)
        internal
        onlyBookeeper
    {
        _regCap = _regCap.add(parValue);
        _paidInCap = _paidInCap.add(paidInAmount);

        emit CapIncrease(parValue, _regCap, paidInAmount, _paidInCap);
    }

    function _capDecrease(uint256 parValue, uint256 paidInAmount)
        internal
        onlyBookeeper
    {
        _regCap -= parValue;
        _paidInCap -= paidInAmount;

        emit CapDecrease(parValue, _regCap, paidInAmount, _paidInCap);
    }

    function _updateShareState(uint256 shareNumber, uint8 state)
        internal
        onlyBookeeper
        onlyExistShare(shareNumber)
    {
        _shares[shareNumber].state = state;

        emit UpdateShareState(shareNumber, state);
    }

    function _updatePaidInDeadline(uint256 shareNumber, uint256 paidInDeadline)
        internal
        onlyBookeeper
        onlyExistShare(shareNumber)
    {
        _shares[shareNumber].paidInDeadline = paidInDeadline;

        emit UpdatePaidInDeadline(shareNumber, paidInDeadline);
    }

    //##################
    //##    读接口    ##
    //##################

    function _shareExist(uint256 shareNumber) internal view returns (bool) {
        return _isShareNum[shareNumber];
    }

    function _getShare(uint256 shareNumber)
        internal
        view
        onlyExistShare(shareNumber)
        returns (
            address shareholder,
            uint8 class,
            uint256 parValue,
            uint256 paidInDeadline,
            uint256 issueDate,
            uint256 issuePrice,
            uint256 obtainedDate,
            uint256 obtainedPrice,
            uint256 paidInDate,
            uint256 paidInAmount,
            uint8 state
        )
    {
        Share storage share = _shares[shareNumber];
        shareholder = share.shareholder;
        class = share.class;
        parValue = share.parValue;
        paidInDeadline = share.paidInAmount;
        issueDate = share.issueDate;
        issuePrice = share.issuePrice;
        obtainedDate = share.obtainedDate;
        obtainedPrice = share.obtainedPrice;
        paidInDate = share.paidInDate;
        paidInAmount = share.paidInAmount;
        state = share.state;
    }

    function _getRegCap() internal view returns (uint256) {
        return _regCap;
    }

    function _getPaidInCap() internal view returns (uint256) {
        return _paidInCap;
    }

    function _getShareNumberList() internal view returns (uint256[]) {
        // require(_shareList.length > 0, "发行股份数量为0");
        return _shareList;
    }

    function _getQtyOfShares() internal view returns (uint256) {
        return _shareList.length;
    }

    function _getClassMembers(uint8 class) internal view returns (address[]) {
        // require(_shareList.length > 0, "发行股份数量为0");
        return _membersOfClass[class];
    }

    function _getClassShares(uint8 class) internal view returns (uint256[]) {
        // require(_shareList.length > 0, "发行股份数量为0");
        return _sharesOfClass[class];
    }
}
