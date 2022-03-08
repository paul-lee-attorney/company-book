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
        uint256 paidInAmount; //实缴金额
        uint256 paidInDeadline; //出资期限（时间戳）
        uint256 issueDate; //发行日期（时间戳）
        uint256 unitPrice; //发行价格（最小单位为分）
        uint8 state; //股票状态 （0：正常，1：出质，2：查封，3：已设定信托，4：代持）
    }

    //注册资本总额
    uint256 public regCap;

    //实缴出资总额
    uint256 public paidInCap;

    //shareNumber => Share
    mapping(uint256 => Share) private _shares;

    //shareNumber => exist?
    mapping(uint256 => bool) public shareExist;

    //股票编号数组
    uint256[] private _sharesList;

    //股份类别 => 股东地址
    mapping(uint8 => address[]) public membersOfClass;

    //股份类别 => 股份编号
    mapping(uint8 => uint256[]) public sharesOfClass;

    //##################
    //##    Event     ##
    //##################

    event IssueShare(
        uint256 indexed shareNumber,
        address shareholder,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 issueDate,
        uint256 unitPrice
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

    event DeregisterShare(uint256 indexed shareNumber);

    event UpdateShareState(uint256 indexed shareNumber, uint8 state);

    event UpdatePaidInDeadline(
        uint256 indexed shareNumber,
        uint256 paidInDeadline
    );

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyNormalState(uint256 shareNumber) {
        require(_shares[shareNumber].state == 0, "Share state NOT normal");
        _;
    }

    modifier onlyExistShare(uint256 shareNumber) {
        require(shareExist[shareNumber], "shareNumber NOT exist");
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
        uint256 paidInAmount,
        uint256 paidInDeadline,
        uint256 issueDate,
        uint256 unitPrice
    ) internal onlyBookeeper {
        require(shareNumber != 0, "shareNumber is ZERO");
        require(!shareExist[shareNumber], "shareNumber is USED");
        require(shareholder != address(0), "shareholder address is ZERO");
        require(issueDate <= now + 2 hours, "issueDate NOT a PAST time");
        require(
            issueDate <= paidInDeadline,
            "issueDate LATER than paidInDeadline"
        );
        require(paidInAmount <= parValue, "paidInAmount BIGGER than parValue");

        Share storage share = _shares[shareNumber];

        share.shareNumber = shareNumber;
        share.shareholder = shareholder;
        share.class = class;
        share.parValue = parValue;
        share.paidInAmount = paidInAmount > 0 ? paidInAmount : 0;
        share.paidInDeadline = paidInDeadline;
        share.issueDate = issueDate > 0 ? issueDate : now;
        share.unitPrice = unitPrice > 0 ? unitPrice : 1;

        shareExist[shareNumber] = true;
        _sharesList.push(shareNumber);

        membersOfClass[class].addValue(shareholder);
        sharesOfClass[class].push(shareNumber);

        emit IssueShare(
            shareNumber,
            shareholder,
            parValue,
            paidInAmount,
            share.issueDate,
            share.unitPrice
        );
    }

    function _splitShare(
        uint256 shareNumber,
        uint256 newShareNumber,
        address newShareholder,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 splitDate,
        uint256 transferPrice
    ) internal onlyBookeeper {
        require(newShareNumber != 0, "newShareNumber is ZERO");
        require(!shareExist[newShareNumber], "newShareNumber has been USED");
        require(newShareholder != address(0), "newShareholder is ZERO");
        require(splitDate <= now + 2 hours, "splitDate not a PAST time");
        require(
            splitDate == 0 || splitDate >= _shares[shareNumber].issueDate,
            "splitDate EARLIER than issueDate"
        );
        require(paidInAmount <= parValue, "paidInAmount BIGGER than parValue");

        Share storage share = _shares[shareNumber];
        Share storage newShare = _shares[newShareNumber];

        newShare.shareNumber = newShareNumber;
        newShare.shareholder = newShareholder;
        newShare.class = share.class;
        newShare.parValue = parValue;
        newShare.paidInAmount = paidInAmount;
        newShare.paidInDeadline = share.paidInDeadline;
        newShare.issueDate = splitDate > 0 ? splitDate : now;
        newShare.unitPrice = transferPrice;

        shareExist[newShareNumber] = true;
        _sharesList.push(newShareNumber);

        membersOfClass[share.class].addValue(newShareholder);
        sharesOfClass[share.class].push(newShareNumber);

        emit IssueShare(
            newShareNumber,
            newShareholder,
            parValue,
            paidInAmount,
            newShare.issueDate,
            transferPrice
        );
    }

    function _deregisterShare(uint256 shareNumber) internal onlyBookeeper {
        uint8 class = _shares[shareNumber].class;
        address shareholder = _shares[shareNumber].shareholder;

        sharesOfClass[class].removeByValue(shareNumber);

        bool flag;

        for (uint8 i = 0; i < sharesOfClass[class].length; i++) {
            if (_shares[sharesOfClass[class][i]].shareholder == shareholder) {
                flag = true;
                break;
            }
        }

        if (!flag) membersOfClass[class].removeByValue(shareholder);

        delete _shares[shareNumber];
        _sharesList.removeByValue(shareNumber);
        shareExist[shareNumber] = false;

        emit DeregisterShare(shareNumber);
    }

    function _payInCapital(
        uint256 shareNumber,
        uint256 amount,
        uint256 paidInDate
    ) internal onlyBookeeper {
        require(paidInDate <= now + 2 hours, "paidInDate NOT a PAST time");

        Share storage share = _shares[shareNumber];

        require(paidInDate <= share.paidInDeadline);
        require(
            share.paidInAmount.add(amount) <= share.parValue,
            "amount overflow"
        );

        share.paidInAmount += amount; //溢出校验已通过
        paidInDate = paidInDate > 0 ? paidInDate : now;

        emit PayInCapital(shareNumber, amount, paidInDate);
    }

    function _subAmountFromShare(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) internal onlyBookeeper {
        require(paidInAmount <= parValue, "paidInAmount BIGGER than parValue");

        Share storage share = _shares[shareNumber];

        require(paidInAmount <= share.paidInAmount, "paidInAmount overflow");

        share.parValue -= parValue;
        share.paidInAmount -= paidInAmount;

        emit SubAmountFromShare(shareNumber, parValue, paidInAmount);
    }

    function _capIncrease(uint256 parValue, uint256 paidInAmount)
        internal
        onlyBookeeper
    {
        regCap = regCap.add(parValue);
        paidInCap = paidInCap.add(paidInAmount);

        emit CapIncrease(parValue, regCap, paidInAmount, paidInCap);
    }

    function _capDecrease(uint256 parValue, uint256 paidInAmount)
        internal
        onlyBookeeper
    {
        regCap -= parValue;
        paidInCap -= paidInAmount;

        emit CapDecrease(parValue, regCap, paidInAmount, paidInCap);
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

    function sharesList() external view returns (uint256[]) {
        return _sharesList;
    }

    function getShare(uint256 shareNumber)
        public
        view
        onlyExistShare(shareNumber)
        returns (
            address shareholder,
            uint8 class,
            uint256 parValue,
            uint256 paidInAmount,
            uint256 paidInDeadline,
            uint256 issueDate,
            uint256 unitPrice,
            uint8 state
        )
    {
        Share storage share = _shares[shareNumber];

        shareholder = share.shareholder;
        class = share.class;
        parValue = share.parValue;
        paidInAmount = share.paidInAmount;
        paidInDeadline = share.paidInAmount;
        issueDate = share.issueDate;
        unitPrice = share.unitPrice;
        state = share.state;
    }
}
