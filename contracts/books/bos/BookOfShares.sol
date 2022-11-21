// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfShares.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

import "../../common/ruting/ROMSetting.sol";

contract BookOfShares is IBookOfShares, ROMSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;


    //Share 股票
    struct Share {
        bytes32 shareNumber; //出资证明书编号（股票编号）
        uint64 paid; //实缴出资
        uint64 par; //票面金额（注册资本面值）
        uint64 cleanPar; //清洁金额（扣除出质、远期票面金额）
        uint32 paidInDeadline; //出资期限（时间戳）
        uint8 state; //股票状态 （0:正常，1:查封）
    }

    // SNInfo: 股票编号编码规则
    // struct SNInfo {
    //     uint16 class; //股份类别（投资轮次）
    //     uint32 sequence; //顺序编码
    //     uint32 issueDate; //发行日期
    //     uint32 unitPrice; //取得价格
    //     uint40 shareholder; //股东编号
    //     uint32 preSN; //来源股票编号索引
    // }

    // _shares[0] {
    //     paid: counterOfShares;
    //     par: counterOfClass;
    // }

    // ssn => Share
    mapping(uint256 => Share) private _shares;

    // ---- PayInCap Locker ----
    struct Locker {
        uint64 amount; //实缴金额
        bytes32 hashLock; //哈希锁
    }
    // ssn => Locker
    mapping(uint256 => Locker) private _lockers;

    //##################
    //##   Modifier   ##
    //##################

    modifier shareExist(uint32 ssn) {
        require(isShare(ssn), "BOS.shareExist: ssn NOT exist");
        _;
    }

    modifier notFreezed(uint32 ssn) {
        require(_shares[ssn].state == 0, "BOS.shareExist: share is freezed");
        _;
    }

    modifier keepersAllowed() {
        require(_gk.isKeeper(uint8(TitleOfKeepers.BOAKeeper), msg.sender) ||
            _gk.isKeeper(uint8(TitleOfKeepers.BOOKeeper), msg.sender) ||
            _gk.isKeeper(uint8(TitleOfKeepers.BOPKeeper), msg.sender) ||
            _gk.isKeeper(uint8(TitleOfKeepers.SHAKeeper), msg.sender), 
            "BOS.keepersAllowed: not have access right");
        _;
    }

    //##################
    //##    写接口    ##
    //##################


    // ==== IssueShare ====

    function issueShare(
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint32 paidInDeadline
    ) external onlyDK {
        require(
            shareNumber.shareholder() > 0,
            "BOS.issueShare: zero shareholder"
        );
        require(
            shareNumber.issueDate() < block.timestamp,
            "BOS.issueShare: future issueDate"
        );
        require(
            shareNumber.issueDate() <= paidInDeadline,
            "BOS.issueShare: issueDate LATER than paidInDeadline"
        );

        require(paid <= par, "paid BIGGER than par");

        // 判断是否需要添加新股东，若添加是否会超过法定人数上限
        _rom.addMember(shareNumber.shareholder());

        _increaseCounterOfShares();

        require(
            shareNumber.ssn() == counterOfShares(),
            "BOS.issueShare: sequence OVER FLOW"
        );

        require(
            shareNumber.class() <= counterOfClasses() + 1,
            "BOS.issueShare: class OVER FLOW"
        );
        if (shareNumber.class() > counterOfClasses())
            _increaseCounterOfClasses();

        if (shareNumber.issueDate() == 0)
            shareNumber = _updateIssueDate(
                shareNumber,
                uint32(block.timestamp)
            );

        // 在《股权簿》中添加新股票（签发新的《出资证明书》）
        _issueShare(shareNumber, paid, par, paidInDeadline);

        // 将股票编号加入《股东名册》记载的股东名下
        _rom.addShareToMember(shareNumber.ssn(), shareNumber.shareholder());

        // 增加“认缴出资”和“实缴出资”金额
        _rom.capIncrease(paid, par);
    }

    // ==== PayInCapital ====

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external shareExist(ssn) onlyDK {
        require(amount > 0, "BOS.setPayInAmount: zero payIn amount");
        require(
            hashLock > bytes32(0),
            "BOS.setPayInAmount: zero payIn hashLock"
        );

        Locker storage locker = _lockers[ssn];
        locker.amount = amount;
        locker.hashLock = hashLock;

        emit SetPayInAmount(_shares[ssn].shareNumber, amount, hashLock);
    }

    function requestPaidInCapital(uint32 ssn, string memory hashKey)
        external
        shareExist(ssn)
        onlyDK
    {
        require(
            _lockers[ssn].hashLock == keccak256(bytes(hashKey)),
            "BOS.requestPaidInCapital: wrong key"
        );

        uint64 amount = _lockers[ssn].amount;

        require(amount > 0, "BOS.requestPaidInCapital: zero payIn amount");

        // 增加“股票”项下实缴出资金额
        _payInCapital(ssn, amount);

        _rom.changeAmtOfMember(
            _shares[ssn].shareNumber.shareholder(),
            amount,
            0,
            false
        );

        // 增加公司的“实缴出资”总额
        _rom.capIncrease(amount, 0);

        // remove payInAmount;
        _lockers[ssn].amount = 0;
    }

    // ==== TransferShare ====

    function transferShare(
        uint32 ssn,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 unitPrice
    ) external onlyDK shareExist(ssn) notFreezed(ssn) {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        require(to > 0, "shareholder userNo is ZERO");
        require(to <= _rc.counterOfUsers(), "shareholder userNo overflow");

        // 判断是否需要新增股东，若需要判断是否超过法定人数上限
        _rom.addMember(to);

        _decreaseShareAmount(ssn, paid, par);

        _increaseCounterOfShares();

        // 在“新股东”名下增加新的股票
        bytes32 shareNumber_1 = createShareNumber(
            shareNumber.class(),
            counterOfShares(),
            uint32(block.timestamp),
            unitPrice,
            to,
            shareNumber.ssn()
        );

        _issueShare(shareNumber_1, paid, par, _shares[ssn].paidInDeadline);

        _rom.addShareToMember(shareNumber_1.ssn(), to);
    }

    function createShareNumber(
        uint16 class,
        uint32 ssn,
        uint32 issueDate,
        uint32 unitPrice,
        uint40 shareholder,
        uint32 preSSN
    ) public pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, class);
        _sn = _sn.dateToSN(2, ssn);
        _sn = _sn.dateToSN(6, issueDate);
        _sn = _sn.dateToSN(10, unitPrice);
        _sn = _sn.acctToSN(14, shareholder);
        _sn = _sn.dateToSN(19, preSSN);

        sn = _sn.bytesToBytes32();
    }

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external onlyDK shareExist(ssn) notFreezed(ssn) {
        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmount(ssn, paid, par);

        // 减少公司“注册资本”和“实缴出资”总额
        _rom.capDecrease(paid, par);
    }

    // ==== CleanPar ====

    function decreaseCleanPar(uint32 ssn, uint64 paid)
        external
        keepersAllowed
        shareExist(ssn)
        notFreezed(ssn)
    {
        require(paid > 0, "ZERO paid");

        Share storage share = _shares[ssn];

        require(paid <= share.cleanPar, "INSUFFICIENT cleanPar");

        share.cleanPar -= paid;

        emit DecreaseCleanPar(share.shareNumber, paid);
    }

    function increaseCleanPar(uint32 ssn, uint64 paid)
        external
        keepersAllowed
        shareExist(ssn)
        notFreezed(ssn)
    {
        require(paid > 0, "ZERO paid");

        Share storage share = _shares[ssn];
        require(share.paid >= (share.cleanPar + paid), "paid overflow");

        share.cleanPar += paid;

        emit IncreaseCleanPar(share.shareNumber, paid);
    }

    // ==== State & PaidInDeadline ====

    /// @param ssn - 股票短号
    /// @param state - 股票状态 （0:正常，1:查封 ）
    function updateStateOfShare(uint32 ssn, uint8 state)
        external
        onlyDK
        shareExist(ssn)
    {
        _shares[ssn].state = state;

        emit UpdateStateOfShare(_shares[ssn].shareNumber, state);
    }

    /// @param ssn - 股票短号
    /// @param paidInDeadline - 实缴出资期限
    function updatePaidInDeadline(uint32 ssn, uint32 paidInDeadline)
        external
        onlyDK
        shareExist(ssn)
    {
        _shares[ssn].paidInDeadline = paidInDeadline;

        emit UpdatePaidInDeadline(_shares[ssn].shareNumber, paidInDeadline);
    }

    // ==== private funcs ====

    function _increaseCounterOfShares() private {
        _shares[0].paid++;
    }

    function _increaseCounterOfClasses() private {
        _shares[0].par++;
    }

    function _updateIssueDate(bytes32 shareNumber, uint32 issueDate)
        private
        pure
        returns (bytes32 sn)
    {
        bytes memory _sn = abi.encodePacked(shareNumber);

        _sn = _sn.dateToSN(6, issueDate);

        sn = _sn.bytesToBytes32();
    }

    function _issueShare(
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint32 paidInDeadline
    ) private {
        uint32 ssn = shareNumber.ssn();

        Share storage share = _shares[ssn];

        share.shareNumber = shareNumber;
        share.paid = paid;
        share.par = par;
        share.cleanPar = paid;
        share.paidInDeadline = paidInDeadline;

        emit IssueShare(shareNumber, paid, par, paidInDeadline);
    }

    function _deregisterShare(uint32 ssn) private {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        delete _shares[ssn];

        emit DeregisterShare(shareNumber);
    }

    function _payInCapital(uint32 ssn, uint64 amount) private {
        uint32 paidInDate = uint32(block.timestamp);

        Share storage share = _shares[ssn];

        require(
            paidInDate <= share.paidInDeadline,
            "BOS._payInCapital: missed payInDeadline"
        );
        require(
            share.paid + amount <= share.par,
            "BOS._payInCapital: amount overflow"
        );

        share.paid += amount; //溢出校验已通过
        share.cleanPar += amount;

        emit PayInCapital(share.shareNumber, amount, paidInDate);
    }

    function _decreaseShareAmount(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) private {
        Share storage share = _shares[ssn];

        require(par > 0, "par is ZERO");
        require(share.par >= par, "par OVERFLOW");
        require(share.cleanPar >= par, "cleanPar OVERFLOW");
        // require(share.state < 4, "FREEZED share");
        require(paid <= par, "paid BIGGER than par");

        // 若拟降低的面值金额等于股票面值，则删除相关股票
        if (par == share.par) {
            _rom.removeShareFromMember(ssn, share.shareNumber.shareholder());
            _deregisterShare(ssn);
        } else {
            // 仅调低认缴和实缴金额，保留原股票
            _subAmountFromShare(ssn, paid, par);
            _rom.changeAmtOfMember(
                share.shareNumber.shareholder(),
                paid,
                par,
                true
            );
        }
    }

    function _subAmountFromShare(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) private {
        Share storage share = _shares[ssn];

        share.paid -= paid;
        share.par -= par;

        share.cleanPar -= paid;

        emit SubAmountFromShare(share.shareNumber, paid, par);
    }

    // ##################
    // ##   查询接口   ##
    // ##################


    function counterOfShares() public view returns (uint32) {
        return uint32(_shares[0].paid);
    }

    function counterOfClasses() public view returns (uint16) {
        return uint16(_shares[0].par);
    }

    // ==== SharesRepo ====

    function isShare(uint32 ssn) public view returns (bool) {
        require(ssn > 0, "BOS.isShare: zero ssn");
        return _shares[ssn].shareNumber.ssn() == ssn;
    }

    function cleanPar(uint32 ssn)
        external
        view
        shareExist(ssn)
        returns (uint64)
    {
        return _shares[ssn].cleanPar;
    }

    function getShare(uint32 ssn)
        external
        view
        shareExist(ssn)
        returns (
            bytes32 shareNumber,
            uint64 paid,
            uint64 par,
            uint32 paidInDeadline,
            uint8 state
        )
    {
        Share storage share = _shares[ssn];

        shareNumber = share.shareNumber;
        paid = share.paid;
        par = share.par;
        paidInDeadline = share.paidInDeadline;
        state = share.state;
    }

    // ==== PayInCapital ====

    function getLocker(uint32 ssn)
        external
        view
        shareExist(ssn)
        returns (uint64 amount, bytes32 hashLock)
    {
        Locker storage locker = _lockers[ssn];

        amount = locker.amount;
        hashLock = locker.hashLock;
    }
}
