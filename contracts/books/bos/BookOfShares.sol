/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IBookOfShares.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/ObjsRepo.sol";
import "../../common/lib/Checkpoints.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/access/AccessControl.sol";
import "../../common/ruting/IBookSetting.sol";
// import "../../common/ruting/BOCSetting.sol";
import "../../common/ruting/SHASetting.sol";

contract BookOfShares is IBookOfShares, SHASetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.SNList;
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    //公司注册号哈希值（统一社会信用号码的“加盐”哈希值）
    bytes32 private _regNumHash;

    // ==== SharesRepo ====

    //Share 股票
    struct Share {
        bytes32 shareNumber; //出资证明书编号（股票编号）
        uint64 par; //票面金额（注册资本面值）
        uint64 paid; //实缴出资
        uint64 cleanPar; //清洁金额（扣除出质、远期票面金额）
        uint32 unitPrice; //发行价格（最小单位为分）
        uint32 paidInDeadline; //出资期限（时间戳）
        uint8 state; //股票状态 （0:正常，1:查封）
    }

    // SNInfo: 股票编号编码规则
    // struct SNInfo {
    //     uint8 class; //股份类别（投资轮次）
    //     uint16 sequence; //顺序编码
    //     uint32 issueDate; //发行日期
    //     uint40 shareholder; //股东编号
    //     uint32 preSN; //来源股票编号索引（sequence + issueDate)
    // }

    Checkpoints.History private _ownersEquity;

    //ssn => Share
    mapping(uint32 => Share) private _shares;

    //类别序列号计数器(2**8-1, 0-255)
    uint8 private _counterOfClasses;

    //股权序列号计数器（2**32-1, 0-4294967295）
    uint32 private _counterOfShares;

    ObjsRepo.SNList private _shareNumbersList;

    // ---- PayInCap Locker ----
    struct Locker {
        uint64 amount; //实缴金额
        bytes32 hashLock; //哈希锁
    }
    // ssn => Locker
    mapping(uint32 => Locker) private _lockers;

    // ==== Member ====

    struct Member {
        EnumerableSet.Bytes32Set sharesInHand;
        Checkpoints.History votesInHand;
        uint16 groupNo;
    }

    mapping(uint40 => Member) private _members;

    EnumerableSet.UintSet private _membersList;

    Checkpoints.History private _qtyOfMembers;

    uint40 private _controller;

    uint16 private _maxQtyOfMembers;

    // ==== Group ====

    // mapping(uint16 => EnumerableSet.UintSet) private _membersOfGroup;

    // EnumerableSet.UintSet private _groupsList;

    // uint16 private _controller;

    // uint16 private _counterOfGroups;

    //##################
    //##   Modifier   ##
    //##################

    modifier notFreezed(uint32 ssn) {
        require(_shares[ssn].state < 4, "FREEZED share");
        _;
    }

    modifier shareExist(uint32 ssn) {
        require(_shareNumbersList.contains(ssn), "ssn NOT exist");
        _;
    }

    modifier onlyMember() {
        require(_membersList.contains(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_membersList.contains(acct), "Acct is NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(bytes32 regNumHash, uint16 max) public {
        _maxQtyOfMembers = max;
        _regNumHash = regNumHash;
    }

    // ==== IssueShare ====

    function issueShare(
        uint40 shareholder,
        uint8 class,
        uint64 par,
        uint64 paid,
        uint32 paidInDeadline,
        uint32 issueDate,
        uint32 issuePrice
    ) external onlyKeeper {
        require(shareholder != address(0), "shareholder address is ZERO");
        require(issueDate <= now + 15 minutes, "issueDate NOT a PAST time");
        require(
            issueDate <= paidInDeadline,
            "issueDate LATER than paidInDeadline"
        );

        require(paid <= par, "paid BIGGER than par");

        // 判断是否需要添加新股东，若添加是否会超过法定人数上限
        _addMember(shareholder);

        _counterOfShares++;

        require(class <= _counterOfClasses, "class OVER FLOW");
        if (class == _counterOfClasses) _counterOfClasses++;

        bytes32 shareNumber = _createShareNumber(
            class,
            _counterOfShares,
            (issueDate == 0) ? uint32(block.timestamp) : issueDate,
            shareholder,
            0
        );

        // 在《股权簿》中添加新股票（签发新的《出资证明书》）
        _issueShare(shareNumber, par, paid, paidInDeadline, issuePrice);

        // 将股票编号加入《股东名册》记载的股东名下
        _addShareToMember(shareNumber.ssn(), shareholder);

        // 增加“认缴出资”和“实缴出资”金额
        _capIncrease(par, paid);
    }

    // ==== PayInCapital ====

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external shareExist(ssn) onlyManager(1) {
        require(amount > 0, "BOS.setPayInAmount: zero payIn amount");
        require(
            hashLock > bytes32(0),
            "BOS.setPayInAmount: zero payIn hashLock"
        );

        Locker storage locker = _lockers[ssn];
        locker.amount = amount;
        locker.hashLock = hashLock;

        emit SetPayInAmount(ssn, amount, hashLock);
    }

    function requestPaidInCapital(uint32 ssn, string hashKey)
        external
        shareExist(ssn)
        onlyManager(1)
    {
        require(
            _lockers[ssn].hashLock == keccak256(bytes(hashKey)),
            "BOS.requestPaidInCapital: wrong key"
        );

        uint64 amount = _lockers[ssn].amount;

        require(amount > 0, "BOS.requestPaidInCapital: zero payIn amount");

        // 增加“股票”项下实缴出资金额
        _payInCapital(ssn, amount);

        _increaseAmountToMember(
            _shares[ssn].shareNumber.shareholder(),
            0,
            amount
        );

        // 增加公司的“实缴出资”总额
        _capIncrease(0, amount);

        // remove payInAmount;
        _lockers[ssn].amount = 0;
    }

    // ==== TransferShare ====

    function transferShare(
        uint32 ssn,
        uint64 par,
        uint64 paid,
        uint40 to,
        uint32 unitPrice
    ) external onlyKeeper {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        require(to > 0, "shareholder userNo is ZERO");
        require(to <= _rc.counterOfUsers(), "shareholder userNo overflow");

        // 判断是否需要新增股东，若需要判断是否超过法定人数上限
        _addMember(to);

        _decreaseShareAmount(ssn, par, paid);

        _counterOfShares++;

        // 在“新股东”名下增加新的股票
        bytes32 shareNumber_1 = _createShareNumber(
            shareNumber.class(),
            _counterOfShares,
            uint32(block.timestamp),
            to,
            shareNumber.ssn()
        );

        _issueShare(
            shareNumber_1,
            par,
            paid,
            _shares[ssn].paidInDeadline,
            unitPrice
        );

        _addShareToMember(ssn, to);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 par,
        uint64 paid
    ) external onlyManager(1) {
        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmount(ssn, par, paid);

        // 减少公司“注册资本”和“实缴出资”总额
        _capDecrease(par, paid);
    }

    function _decreaseShareAmount(
        uint32 ssn,
        uint64 par,
        uint64 paid
    ) private {
        Share storage share = _shares[ssn];

        require(par > 0, "par is ZERO");
        require(share.par >= par, "par OVERFLOW");
        require(share.cleanPar >= par, "cleanPar OVERFLOW");
        require(share.state < 4, "FREEZED share");
        require(paid <= par, "paid BIGGER than par");

        // 若拟降低的面值金额等于股票面值，则删除相关股票
        if (par == share.par) {
            _removeShareFromMember(ssn, share.shareNumber.shareholder());
            _deregisterShare(ssn);
            // _updateMembersList(share.shareNumber.shareholder());
        } else {
            // 仅调低认缴和实缴金额，保留原股票
            _subAmountFromShare(ssn, par, paid);
            _decreaseAmountFromMember(
                _shares[ssn].shareNumber.shareholder(),
                par,
                paid
            );
        }
    }

    // ==== SharesRepo ====

    function _createShareNumber(
        uint8 class,
        uint32 ssn,
        uint32 issueDate,
        uint40 shareholder,
        uint32 preSSN
    ) internal pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn = _sn.dateToSN(1, ssn);
        _sn = _sn.dateToSN(5, issueDate);
        _sn = _sn.acctToSN(9, shareholder);
        _sn = _sn.dateToSN(14, preSSN);

        sn = _sn.bytesToBytes32();
    }

    function _issueShare(
        bytes32 shareNumber,
        uint64 par,
        uint64 paid,
        uint32 paidInDeadline,
        uint32 unitPrice
    ) internal {
        uint32 ssn = shareNumber.ssn();

        Share storage share = _shares[ssn];

        share.shareNumber = shareNumber;
        share.par = par;
        share.paid = paid;
        share.cleanPar = paid;
        share.paidInDeadline = paidInDeadline;
        share.unitPrice = unitPrice;

        _shareNumbersList.add(shareNumber);

        emit IssueShare(shareNumber, par, paid, paidInDeadline, unitPrice);
    }

    function _deregisterShare(uint32 ssn) internal {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        delete _shares[ssn];

        _shareNumbersList.remove(shareNumber);

        emit DeregisterShare(shareNumber);
    }

    function _payInCapital(uint32 ssn, uint64 amount) internal {
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

        emit PayInCapital(ssn, amount, paidInDate);
    }

    function _subAmountFromShare(
        uint32 ssn,
        uint64 par,
        uint64 paid
    ) internal {
        Share storage share = _shares[ssn];

        share.par -= par;
        share.paid -= paid;
        share.cleanPar -= paid;

        emit SubAmountFromShare(ssn, par, paid);
    }

    function _capIncrease(uint64 par, uint64 paid) internal {
        (uint64 regCap, uint64 paidCap) = _ownersEquity.latest();

        regCap += par;
        paidCap += paid;

        uint64 blocknumber = _ownersEquity.push(regCap, paidCap);

        emit CapIncrease(par, regCap, paid, paidCap, blocknumber);
    }

    function _capDecrease(uint64 par, uint64 paid) internal {
        (uint64 regCap, uint64 paidCap) = _ownersEquity.latest();

        regCap -= par;
        paidCap -= paid;

        uint64 blocknumber = _ownersEquity.push(regCap, paidCap);

        emit CapDecrease(par, regCap, paid, paidCap, blocknumber);
    }

    function decreaseCleanPar(uint32 ssn, uint64 paid)
        external
        onlyKeeper
        shareExist(ssn)
        notFreezed(ssn)
    {
        require(paid > 0, "ZERO paid");

        Share storage share = _shares[ssn];

        require(paid <= share.cleanPar, "INSUFFICIENT cleanPar");

        share.cleanPar -= paid;

        emit DecreaseCleanPar(ssn, paid);
    }

    function increaseCleanPar(uint32 ssn, uint64 paid)
        external
        onlyKeeper
        shareExist(ssn)
        notFreezed(ssn)
    {
        require(paid > 0, "ZERO paid");

        Share storage share = _shares[ssn];
        require(share.paid >= (share.cleanPar + paid), "paid overflow");

        share.cleanPar += paid;

        if (share.cleanPar == share.paid && share.state != 4) share.state = 0;

        emit IncreaseCleanPar(ssn, paid);
    }

    /// @param ssn - 股票短号
    /// @param state - 股票状态 （0：正常，1：出质，2：远期占用; 3:1+2; 4:查封; 5:1+4; 6:2+4; 7:1+2+4 ）
    function updateShareState(uint32 ssn, uint8 state)
        external
        onlyKeeper
        shareExist(ssn)
    {
        _shares[ssn].state = state;

        emit UpdateShareState(ssn, state);
    }

    /// @param ssn - 股票短号
    /// @param paidInDeadline - 实缴出资期限
    function updatePaidInDeadline(uint32 ssn, uint32 paidInDeadline)
        external
        onlyKeeper
        shareExist(ssn)
    {
        _shares[ssn].paidInDeadline = paidInDeadline;

        emit UpdatePaidInDeadline(ssn, paidInDeadline);
    }

    // ==== MembersRepo ====

    function setMaxQtyOfMembers(uint16 max) external onlyManager(1) {
        _maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(uint40 acct) internal {
        require(
            _membersList.length() < _maxQtyOfMembers,
            "Qty of Members overflow"
        );

        if (_membersList.add(acct)) {
            // _rc.investIn(acct, par, true);
            _qtyOfMembers.push(uint64(_membersList.length()), 1);
            emit AddMember(acct, uint16(_membersList.length()));
        }
    }

    function _removeMember(uint40 acct) internal {
        if (_membersList.remove(acct)) {
            Member storage member = _members[acct];

            delete member.sharesInHand;

            // if (_boc.groupNo(acct) > 0)
            //     _boc.removeMemberFromGroup(acct, _boc.groupNo(acct));
            _qtyOfMembers.push(uint64(_membersList.length()), 0);
            // _rc.exitOut(acct);
            emit RemoveMember(acct, uint16(_membersList.length()));
        }
    }

    function _addShareToMember(uint32 ssn, uint40 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _increaseAmountToMember(acct, share.par, share.paid);

        _members[acct].sharesInHand.add(share.shareNumber);

        emit AddShareToMember(share.shareNumber, acct);
    }

    function _removeShareFromMember(uint32 ssn, uint40 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _members[acct].sharesInHand.remove(share.shareNumber);

        if (_members[acct].sharesInHand.length() == 0) _removeMember(acct);
        else _decreaseAmountFromMember(acct, share.par, share.paid);

        emit RemoveShareFromMember(share.shareNumber, acct);
    }

    function _increaseAmountToMember(
        uint40 acct,
        uint64 par,
        uint64 paid
    ) internal {
        (uint64 oldPar, uint64 oldPaid) = _members[acct].votesInHand.latest();

        uint64 curPar = oldPar + par;
        uint64 curPaid = oldPaid + paid;

        uint64 blocknumber = _members[acct].votesInHand.push(curPar, curPaid);

        // _rc.updateParValue(acct, curPar);

        emit IncreaseAmountToMember(acct, par, paid, blocknumber);
    }

    function _decreaseAmountFromMember(
        uint40 acct,
        uint64 par,
        uint64 paid
    ) internal {
        (uint64 oldPar, uint64 oldPaid) = _members[acct].votesInHand.latest();

        require(oldPar >= par, "par over flow");
        require(oldPaid >= paid, "paid over flow");

        uint64 blocknumber = _members[acct].votesInHand.push(
            oldPar - par,
            oldPaid - paid
        );

        // _rc.updateParValue(acct, uint64(oldPar - par));

        emit DecreaseAmountFromMember(acct, par, paid, blocknumber);
    }

    function addMemberToGroup(uint40 acct, uint16 group)
        external
        memberExist(acct)
        onlyKeeper
    {
        Member storage member = _members[acct];
        require(
            member.groupNo == 0,
            "BOS.addMemberToGroup: member's groupNo not ZERO"
        );

        member.groupNo = group;
        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(uint40 acct, uint16 group)
        external
        memberExist(acct)
        onlyKeeper
    {
        Member storage member = _members[acct];
        require(member.groupNo == group, "BOS.addMemberToGroup: wrong groupNo");

        member.groupNo = 0;
        emit RemoveMemberFromGroup(acct, group);
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    function verifyRegNum(string regNum)
        external
        view
        onlyMember
        returns (bool)
    {
        return _regNumHash == keccak256(bytes(regNum));
    }

    // ==== SharesRepo ====
    function counterOfShares() external view returns (uint32) {
        return _counterOfShares;
    }

    function counterOfClasses() external view returns (uint8) {
        return _counterOfClasses;
    }

    function regCap() external view returns (uint64 par) {
        (par, ) = _ownersEquity.latest();
    }

    function paidCap() external view returns (uint64 paid) {
        (, paid) = _ownersEquity.latest();
    }

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 par, uint64 paid)
    {
        (par, paid) = _ownersEquity.getAtBlock(blocknumber);
    }

    function totalVote() external view returns (uint64 vote) {
        if (_getSHA().basedOnPar()) (vote, ) = _ownersEquity.latest();
        else (, vote) = _ownersEquity.latest();
    }

    function totalVoteAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 vote)
    {
        if (_getSHA().basedOnPar())
            (vote, ) = _ownersEquity.getAtBlock(blocknumber);
        else (, vote) = _ownersEquity.getAtBlock(blocknumber);
    }

    function isShare(uint32 ssn) external view returns (bool) {
        return _shareNumbersList.contains(ssn);
    }

    function snList() external view returns (bytes32[]) {
        return _shareNumbersList.values();
    }

    function cleanPar(uint32 ssn) external view returns (uint64) {
        return _shares[ssn].cleanPar;
    }

    function getShare(uint32 ssn)
        external
        view
        shareExist(ssn)
        returns (
            bytes32 shareNumber,
            uint64 par,
            uint64 paid,
            uint32 paidInDeadline,
            uint32 unitPrice,
            uint8 state
        )
    {
        Share storage share = _shares[ssn];

        shareNumber = share.shareNumber;
        par = share.par;
        paid = share.paid;
        paidInDeadline = share.paidInDeadline;
        unitPrice = share.unitPrice;
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

    // ==== MembersRepo ====

    function maxQtyOfMembers() external view returns (uint16) {
        return _maxQtyOfMembers;
    }

    function isMember(uint40 acct) public view returns (bool) {
        return _membersList.contains(acct);
    }

    function members() external view returns (uint40[]) {
        return _membersList.valuesToUint40();
    }

    function qtyOfMembersAtBlock(uint64 blockNumber)
        external
        view
        returns (uint16)
    {
        (uint256 qty, ) = _qtyOfMembers.getAtBlock(blockNumber);
        return (uint16(qty));
    }

    function parInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 par)
    {
        (par, ) = _members[acct].votesInHand.latest();
    }

    function paidInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 paid)
    {
        (, paid) = _members[acct].votesInHand.latest();
    }

    function votesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 vote)
    {
        if (_getSHA().basedOnPar())
            (vote, ) = _members[acct].votesInHand.latest();
        else (, vote) = _members[acct].votesInHand.latest();
    }

    function votesAtBlock(uint40 acct, uint64 blockNumber)
        external
        view
        returns (uint64 vote)
    {
        if (_getSHA().basedOnPar())
            (vote, ) = _members[acct].votesInHand.getAtBlock(blockNumber);
        else (, vote) = _members[acct].votesInHand.getAtBlock(blockNumber);
    }

    function sharesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (bytes32[])
    {
        return _members[acct].sharesInHand.values();
    }

    function groupNo(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint16)
    {
        return _members[acct].groupNo;
    }
}
