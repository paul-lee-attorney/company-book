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

    modifier onlyNormal(uint256 shareNumber) {
        Share storage share = _shares[shareNumber];
        require(share.state == 0, "股权 状态错误");
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
    ) internal onlyBookkeeper {
        require(shareNumber != 0, "股票编号 不能为 0 ");
        require(!_isShareNum[shareNumber], "股票编号 已经存在");

        require(shareholder != address(0), "股东地址不能为 0 ");

        require(issueDate <= now + 2 hours, "发行日不能晚于当前时间+2小时");
        require(issueDate <= paidInDeadline, "出资截止日不能早于股权发行日");
        require(
            obtainedDate == 0 || issueDate <= obtainedDate,
            "股权取得日不能早于发行日"
        );

        require(
            paidInDate == 0 || issueDate <= paidInDate,
            "实缴出资日不能早于股权发行日"
        );
        require(paidInDate <= paidInDeadline, "实缴出资日不能晚于出资截止日");

        require(paidInAmount <= parValue, "实缴出资不能超过认缴出资");

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
    ) internal onlyBookkeeper {
        require(newShareNumber != 0, "新股票编号 不能为 0");
        require(!_isShareNum[newShareNumber], "股票编号 已经存在");

        require(newShareholder != address(0), "股东地址不能为 0 ");
        require(splitDate <= now + 2 hours, "发行日不能晚于当前时间+2小时");

        require(paidInAmount <= parValue, "实缴出资不能超过认缴出资");

        Share storage share = _shares[shareNumber];

        require(
            splitDate == 0 || share.issueDate <= splitDate,
            "股权取得日不能早于发行日"
        );

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

    function _deregisterShare(uint256 shareNumber) internal onlyBookkeeper {
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
    ) internal onlyBookkeeper {
        require(
            paidInDate == 0 || paidInDate <= now + 2 hours,
            "实缴日期不能晚于当前时间+2小时"
        );

        Share storage share = _shares[shareNumber];

        require(
            paidInDate == 0 || paidInDate <= share.paidInDeadline,
            "实缴日期晚于截止日"
        );
        require(
            share.paidInAmount.add(amount) <= share.parValue,
            "实缴资金超出认缴总额"
        );

        share.paidInAmount += amount; //溢出校验已通过
        share.paidInDate = paidInDate > 0 ? paidInDate : now;

        emit PayInCapital(shareNumber, amount, share.paidInDate);
    }

    function _subAmountFromShare(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) internal onlyBookkeeper {
        Share storage share = _shares[shareNumber];

        require(
            paidInAmount <= parValue && paidInAmount <= share.paidInAmount,
            "拟转让 “实缴出资” 金额溢出"
        );

        share.parValue -= parValue;
        share.paidInAmount -= paidInAmount;

        emit SubAmountFromShare(shareNumber, parValue, paidInAmount);
    }

    function _capIncrease(uint256 parValue, uint256 paidInAmount)
        internal
        onlyBookkeeper
    {
        _regCap = _regCap.add(parValue);
        _paidInCap = _paidInCap.add(paidInAmount);

        emit CapIncrease(parValue, _regCap, paidInAmount, _paidInCap);
    }

    function _capDecrease(uint256 parValue, uint256 paidInAmount)
        internal
        onlyBookkeeper
    {
        _regCap -= parValue;
        _paidInCap -= paidInAmount;

        emit CapDecrease(parValue, _regCap, paidInAmount, _paidInCap);
    }

    function _updateShareState(uint256 shareNumber, uint8 state)
        internal
        onlyBookkeeper
    {
        require(_isShareNum[shareNumber], "标的股权不存在");

        _shares[shareNumber].state = state;

        emit UpdateShareState(shareNumber, state);
    }

    function _updatePaidInDeadline(uint256 shareNumber, uint256 paidInDeadline)
        internal
        onlyBookkeeper
    {
        require(_isShareNum[shareNumber], "标的股权不存在");

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
        require(_isShareNum[shareNumber], "目标股权不存在");

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
        require(_shareList.length > 0, "发行股份数量为0");
        return _shareList;
    }

    function _getQtyOfShares() internal view returns (uint256) {
        return _shareList.length;
    }

    function _getClassMembers(uint8 class) internal view returns (address[]) {
        require(_shareList.length > 0, "发行股份数量为0");
        return _membersOfClass[class];
    }

    function _getClassShares(uint8 class) internal view returns (uint256[]) {
        require(_shareList.length > 0, "发行股份数量为0");
        return _sharesOfClass[class];
    }
}
