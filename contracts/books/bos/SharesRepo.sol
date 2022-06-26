/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/access/AccessControl.sol";

import "../../common/ruting/SHASetting.sol";

import "../../common/lib/Checkpoints.sol";

contract SharesRepo is SHASetting {
    using SNFactory for bytes;
    // using SNFactory for bytes32;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.SNList;
    using Checkpoints for Checkpoints.History;

    // using ArrayUtils for uint256[];
    // using ArrayUtils for address[];
    // using ArrayUtils for bytes32[];

    //Share 股票
    struct Share {
        bytes32 shareNumber; //出资证明书编号（股票编号）
        uint256 parValue; //票面金额（注册资本面值）
        uint256 paidPar; //实缴出资
        uint256 cleanPar; //清洁金额（扣除出质、远期票面金额）
        uint32 paidInDeadline; //出资期限（时间戳）
        uint256 unitPrice; //发行价格（最小单位为分）
        uint8 state; //股票状态 （0：正常，1：出质，2：远期占用; 3:1+2; 4:查封; 5:1+4; 6:2+4; 7:1+2+4 ）
    }

    // SNInfo: 股票编号编码规则
    // struct SNInfo {
    //     uint8 class; //股份类别（投资轮次）
    //     uint16 sequence; //顺序编码
    //     uint32 issueDate; //发行日期
    //     uint40 shareholder; //股东编号
    //     bytes5 preSN; //来源股票编号索引（sequence + issueDate(前24位, 精度误差256秒))
    // }

    Checkpoints.History private _ownersEquity;

    // //注册资本总额
    // uint256 private _regCap;

    // //实缴出资总额
    // uint256 private _paidCap;

    //ssn => Share
    mapping(bytes6 => Share) internal _shares;

    // //ssn => exist?
    // mapping(bytes6 => bool) public isShare;

    //股权序列号计数器（2**16-1, 0-65535）
    uint16 public counterOfShares;

    //类别序列号计数器(2**8-1, 0-255)
    uint8 public counterOfClasses;

    // //shareNumber数组
    // bytes32[] internal _snList;

    EnumerableSet.SNList internal _snList;

    //##################
    //##    Event     ##
    //##################

    event IssueShare(
        bytes32 indexed shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 paidInDeadline,
        uint256 unitPrice
    );

    event PayInCapital(bytes6 indexed ssn, uint256 amount, uint32 paidInDate);

    event SubAmountFromShare(
        bytes6 indexed ssn,
        uint256 parValue,
        uint256 paidPar
    );

    event CapIncrease(
        uint256 parValue,
        uint256 regCap,
        uint256 paidPar,
        uint256 paiInCap,
        uint256 blocknumber
    );

    event CapDecrease(
        uint256 parValue,
        uint256 regCap,
        uint256 paidPar,
        uint256 paidCap,
        uint256 blocknumber
    );

    event DeregisterShare(bytes32 indexed shareNumber);

    event UpdateShareState(bytes6 indexed ssn, uint8 state);

    event UpdatePaidInDeadline(bytes6 indexed ssn, uint32 paidInDeadline);

    event DecreaseCleanPar(bytes6 ssn, uint256 parValue);

    event IncreaseCleanPar(bytes6 ssn, uint256 parValue);

    event PledgeShare(bytes6 indexed ssn, uint256 parValue);

    //##################
    //##   Modifier   ##
    //##################

    modifier notFreezed(bytes6 ssn) {
        require(_shares[ssn].state < 4, "FREEZED share");
        _;
    }

    modifier shareExist(bytes6 ssn) {
        require(_snList.contains(ssn), "ssn NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createShareNumber(
        uint8 class,
        uint16 sequenceNumber,
        uint32 issueDate,
        uint40 shareholder,
        bytes6 preSN
    ) internal pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn = _sn.sequenceToSN(1, sequenceNumber);
        _sn = _sn.dateToSN(3, issueDate);
        _sn = _sn.acctToSN(7, shareholder);
        _sn = _sn.shortToSN(12, preSN);

        sn = _sn.bytesToBytes32();
    }

    function _issueShare(
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 paidInDeadline,
        uint256 unitPrice
    ) internal {
        // require(!isShare[shareNumber], "shareNumber is USED");

        bytes6 ssn = shareNumber.short();

        Share storage share = _shares[ssn];

        share.shareNumber = shareNumber;
        share.parValue = parValue;
        share.paidPar = paidPar;
        share.cleanPar = paidPar;
        share.paidInDeadline = paidInDeadline;
        share.unitPrice = unitPrice;

        // isShare[ssn] = true;
        // shareNumber.insertToQue(_snList);

        _snList.add(shareNumber);

        emit IssueShare(
            shareNumber,
            parValue,
            paidPar,
            paidInDeadline,
            unitPrice
        );
    }

    function _deregisterShare(bytes6 ssn) internal {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        delete _shares[ssn];

        _snList.remove(shareNumber);

        // _snList.removeByValue(shareNumber);
        // isShare[ssn] = false;

        emit DeregisterShare(shareNumber);
    }

    function _payInCapital(
        bytes6 ssn,
        uint256 amount,
        uint32 paidInDate
    ) internal {
        require(paidInDate > 0, "ZERO paidInDate");
        require(paidInDate <= now + 2 hours, "paidInDate NOT a PAST time");

        Share storage share = _shares[ssn];

        require(paidInDate <= share.paidInDeadline);
        require(share.paidPar + amount <= share.parValue, "amount overflow");

        share.paidPar += amount; //溢出校验已通过
        share.cleanPar += amount;

        emit PayInCapital(ssn, amount, paidInDate);
    }

    function _subAmountFromShare(
        bytes6 ssn,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        // require(paidPar <= parValue, "paidPar BIGGER than parValue");

        Share storage share = _shares[ssn];

        // require(paidPar <= share.paidPar, "paidPar overflow");

        share.parValue -= parValue;
        share.paidPar -= paidPar;
        share.cleanPar -= paidPar;

        emit SubAmountFromShare(ssn, parValue, paidPar);
    }

    function _capIncrease(uint256 par, uint256 paid) internal {
        (uint256 regCap, uint256 paidCap) = _ownersEquity.latest();

        regCap += par;
        paidCap += paid;

        uint256 blocknumber = _ownersEquity.push(regCap, paidCap);

        emit CapIncrease(par, regCap, paid, paidCap, blocknumber);
    }

    function _capDecrease(uint256 par, uint256 paid) internal {
        (uint256 regCap, uint256 paidCap) = _ownersEquity.latest();

        regCap -= par;
        paidCap -= paid;

        uint256 blocknumber = _ownersEquity.push(regCap, paidCap);

        emit CapDecrease(par, regCap, paid, paidCap, blocknumber);
    }

    function decreaseCleanPar(bytes6 ssn, uint256 parValue)
        external
        onlyKeeper
        shareExist(ssn)
        notFreezed(ssn)
    {
        require(parValue > 0, "ZERO parValue");

        Share storage share = _shares[ssn];

        require(parValue <= share.cleanPar, "INSUFFICIENT cleanPar");

        share.cleanPar -= parValue;

        if (share.state < 2) share.state += 2;

        emit DecreaseCleanPar(ssn, parValue);
    }

    function increaseCleanPar(bytes6 ssn, uint256 paidPar)
        external
        shareExist(ssn)
    {
        require(paidPar > 0, "ZERO paidPar");

        Share storage share = _shares[ssn];
        require(
            share.paidPar >= (share.cleanPar + paidPar),
            "paidPar overflow"
        );

        share.cleanPar += paidPar;

        if (share.cleanPar == share.paidPar && share.state != 4)
            share.state = 0;

        emit IncreaseCleanPar(ssn, paidPar);
    }

    /// @param ssn - 股票短号
    /// @param state - 股票状态 （0：正常，1：出质，2：远期占用; 3:1+2; 4:查封; 5:1+4; 6:2+4; 7:1+2+4 ）
    function updateShareState(bytes6 ssn, uint8 state)
        external
        onlyKeeper
        shareExist(ssn)
    {
        _shares[ssn].state = state;

        emit UpdateShareState(ssn, state);
    }

    /// @param ssn - 股票短号
    /// @param paidInDeadline - 实缴出资期限
    function updatePaidInDeadline(bytes6 ssn, uint32 paidInDeadline)
        external
        onlyKeeper
        shareExist(ssn)
    {
        _shares[ssn].paidInDeadline = paidInDeadline;

        emit UpdatePaidInDeadline(ssn, paidInDeadline);
    }

    //##################
    //##    读接口    ##
    //##################

    function regCap() external view onlyUser returns (uint256 par) {
        (par, ) = _ownersEquity.latest();
    }

    function paidCap() external view onlyUser returns (uint256 paid) {
        (, paid) = _ownersEquity.latest();
    }

    function capAtBlock(uint256 blocknumber)
        external
        view
        onlyUser
        returns (uint256 par, uint256 paid)
    {
        (par, paid) = _ownersEquity.getAtBlock(blocknumber);
    }

    function totalVoteAtBlock(uint256 blocknumber)
        external
        view
        onlyUser
        returns (uint256 vote)
    {
        if (_getSHA().basedOnPar())
            (vote, ) = _ownersEquity.getAtBlock(blocknumber);
        else (, vote) = _ownersEquity.getAtBlock(blocknumber);
    }

    function isShare(bytes6 ssn) external view onlyUser returns (bool) {
        return _snList.contains(ssn);
    }

    function snList() external view onlyUser returns (bytes32[]) {
        return _snList.values();
    }

    function cleanPar(bytes6 ssn) external view onlyUser returns (uint256) {
        return _shares[ssn].cleanPar;
    }

    function getShare(bytes6 ssn)
        public
        view
        shareExist(ssn)
        onlyUser
        returns (
            bytes32 shareNumber,
            uint256 parValue,
            uint256 paidPar,
            uint32 paidInDeadline,
            uint256 unitPrice,
            uint8 state
        )
    {
        Share storage share = _shares[ssn];

        shareNumber = share.shareNumber;
        parValue = share.parValue;
        paidPar = share.paidPar;
        paidInDeadline = share.paidInDeadline;
        unitPrice = share.unitPrice;
        state = share.state;
    }
}
