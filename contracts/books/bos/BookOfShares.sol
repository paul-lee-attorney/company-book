/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// import "./MembersRepo.sol";
import "./IBookOfShares.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/ObjsRepo.sol";
import "../../common/lib/Checkpoints.sol";
import "../../common/lib/EnumerableSet.sol";

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
        uint64 parValue; //票面金额（注册资本面值）
        uint64 paidPar; //实缴出资
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
    //     bytes6 preSN; //来源股票编号索引（sequence + issueDate)
    // }

    Checkpoints.History private _ownersEquity;

    //ssn => Share
    mapping(bytes6 => Share) private _shares;

    //股权序列号计数器（2**16-1, 0-65535）
    uint16 private _counterOfShares;

    //类别序列号计数器(2**8-1, 0-255)
    uint8 private _counterOfClasses;

    ObjsRepo.SNList private _snList;

    // ==== Member ====

    EnumerableSet.UintSet private _members;

    Checkpoints.History private _qtyOfMembers;

    mapping(uint40 => EnumerableSet.Bytes32Set) private _sharesInHand;

    mapping(uint40 => Checkpoints.History) private _votesInHand;

    uint8 private _maxQtyOfMembers;

    // ==== Group ====

    mapping(uint16 => EnumerableSet.UintSet) private _membersOfGroup;

    mapping(uint40 => uint16) private _groupNo;

    EnumerableSet.UintSet private _groupsList;

    uint16 private _controller;

    uint16 private _counterOfGroups;

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

    modifier onlyMember() {
        require(_members.contains(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_members.contains(acct), "Acct is NOT Member");
        _;
    }

    modifier groupExist(uint16 group) {
        require(_groupsList.contains(group), "group is NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(bytes32 regNumHash, uint8 max) public {
        _maxQtyOfMembers = max;
        _regNumHash = regNumHash;
    }

    // ==== IssueShare ====

    function issueShare(
        uint40 shareholder,
        uint8 class,
        uint64 parValue,
        uint64 paidPar,
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

        require(paidPar <= parValue, "paidPar BIGGER than parValue");

        // 判断是否需要添加新股东，若添加是否会超过法定人数上限
        _addMember(shareholder, parValue);

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
        _issueShare(shareNumber, parValue, paidPar, paidInDeadline, issuePrice);

        // 将股票编号加入《股东名册》记载的股东名下
        _addShareToMember(shareNumber.short(), shareholder);

        // 增加“认缴出资”和“实缴出资”金额
        _capIncrease(parValue, paidPar);
    }

    // ==== PayInCapital ====

    function payInCapital(
        bytes6 ssn,
        uint64 amount,
        uint32 paidInDate
    ) external onlyKeeper {
        // 增加“股票”项下实缴出资金额
        _payInCapital(ssn, amount, paidInDate);

        _increaseAmountToMember(
            _shares[ssn].shareNumber.shareholder(),
            0,
            amount
        );

        // 增加公司的“实缴出资”总额
        _capIncrease(0, amount);
    }

    // ==== TransferShare ====

    function transferShare(
        bytes6 ssn,
        uint64 parValue,
        uint64 paidPar,
        uint40 to,
        uint32 unitPrice
    ) external onlyKeeper {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        require(to > 0, "shareholder userNo is ZERO");
        require(to <= _rc.counterOfUsers(), "shareholder userNo overflow");

        // 判断是否需要新增股东，若需要判断是否超过法定人数上限
        _addMember(to, uint64(parValue));

        _decreaseShareAmount(ssn, parValue, paidPar);

        _counterOfShares++;

        // 在“新股东”名下增加新的股票
        bytes32 shareNumber_1 = _createShareNumber(
            shareNumber.class(),
            _counterOfShares,
            uint32(block.timestamp),
            to,
            bytes5(shareNumber << 8)
        );

        _issueShare(
            shareNumber_1,
            parValue,
            paidPar,
            _shares[ssn].paidInDeadline,
            unitPrice
        );

        _addShareToMember(ssn, to);
    }

    function decreaseCapital(
        bytes6 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external onlyKeeper {
        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmount(ssn, parValue, paidPar);

        // 减少公司“注册资本”和“实缴出资”总额
        _capDecrease(parValue, paidPar);
    }

    function _decreaseShareAmount(
        bytes6 ssn,
        uint64 parValue,
        uint64 paidPar
    ) private {
        Share storage share = _shares[ssn];

        require(parValue > 0, "parValue is ZERO");
        require(share.parValue >= parValue, "parValue OVERFLOW");
        require(share.cleanPar >= parValue, "cleanPar OVERFLOW");
        require(share.state < 4, "FREEZED share");
        require(paidPar <= parValue, "paidPar BIGGER than parValue");

        // 若拟降低的面值金额等于股票面值，则删除相关股票
        if (parValue == share.parValue) {
            _removeShareFromMember(ssn, share.shareNumber.shareholder());
            _deregisterShare(ssn);
            // _updateMembersList(share.shareNumber.shareholder());
        } else {
            // 仅调低认缴和实缴金额，保留原股票
            _subAmountFromShare(ssn, parValue, paidPar);
            _decreaseAmountFromMember(
                _shares[ssn].shareNumber.shareholder(),
                parValue,
                paidPar
            );
        }
    }

    // ==== SharesRepo ====

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
        uint64 parValue,
        uint64 paidPar,
        uint32 paidInDeadline,
        uint32 unitPrice
    ) internal {
        bytes6 ssn = shareNumber.short();

        Share storage share = _shares[ssn];

        share.shareNumber = shareNumber;
        share.parValue = parValue;
        share.paidPar = paidPar;
        share.cleanPar = paidPar;
        share.paidInDeadline = paidInDeadline;
        share.unitPrice = unitPrice;

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

        emit DeregisterShare(shareNumber);
    }

    function _payInCapital(
        bytes6 ssn,
        uint64 amount,
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
        uint64 parValue,
        uint64 paidPar
    ) internal {
        Share storage share = _shares[ssn];

        share.parValue -= parValue;
        share.paidPar -= paidPar;
        share.cleanPar -= paidPar;

        emit SubAmountFromShare(ssn, parValue, paidPar);
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

    function decreaseCleanPar(bytes6 ssn, uint64 parValue)
        external
        onlyKeeper
        shareExist(ssn)
        notFreezed(ssn)
    {
        require(parValue > 0, "ZERO parValue");

        Share storage share = _shares[ssn];

        require(parValue <= share.cleanPar, "INSUFFICIENT cleanPar");

        share.cleanPar -= parValue;

        emit DecreaseCleanPar(ssn, parValue);
    }

    function increaseCleanPar(bytes6 ssn, uint64 paidPar)
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

    // ==== MembersRepo ====

    function setMaxQtyOfMembers(uint8 max) external onlyOwner {
        _maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(uint40 acct, uint64 parValue) internal {
        require(
            _members.length() < _maxQtyOfMembers,
            "Qty of Members overflow"
        );

        if (_members.add(acct)) {
            _rc.investIn(acct, parValue, true);
            _qtyOfMembers.push(uint64(_members.length()), 1);
            emit AddMember(acct, uint8(_members.length()));
        }
    }

    function _removeMember(uint40 acct) internal {
        if (_members.remove(acct)) {
            delete _sharesInHand[acct];
            if (_groupNo[acct] > 0) removeMemberFromGroup(acct, _groupNo[acct]);
            _qtyOfMembers.push(uint64(_members.length()), 0);
            _rc.exitOut(acct);
            emit RemoveMember(acct, uint8(_members.length()));
        }
    }

    function _addShareToMember(bytes6 ssn, uint40 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _increaseAmountToMember(acct, share.parValue, share.paidPar);
        _sharesInHand[acct].add(share.shareNumber);

        emit AddShareToMember(share.shareNumber, acct);
    }

    function _removeShareFromMember(bytes6 ssn, uint40 acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        Share storage share = _shares[ssn];

        _sharesInHand[acct].remove(share.shareNumber);

        if (_sharesInHand[acct].length() == 0) _removeMember(acct);
        else _decreaseAmountFromMember(acct, share.parValue, share.paidPar);

        emit RemoveShareFromMember(share.shareNumber, acct);
    }

    function _increaseAmountToMember(
        uint40 acct,
        uint64 parValue,
        uint64 paidPar
    ) internal {
        (uint64 oldPar, uint64 oldPaid) = _votesInHand[acct].latest();

        uint64 blocknumber = _votesInHand[acct].push(
            oldPar + parValue,
            oldPaid + paidPar
        );

        _rc.updateParValue(acct, uint64(oldPar + parValue));

        emit IncreaseAmountToMember(acct, parValue, paidPar, blocknumber);
    }

    function _decreaseAmountFromMember(
        uint40 acct,
        uint64 parValue,
        uint64 paidPar
    ) internal {
        (uint64 oldPar, uint64 oldPaid) = _votesInHand[acct].latest();

        require(oldPar >= parValue, "parValue over flow");
        require(oldPaid >= paidPar, "paidPar over flow");

        uint64 blocknumber = _votesInHand[acct].push(
            oldPar - parValue,
            oldPaid - paidPar
        );

        _rc.updateParValue(acct, uint64(oldPar - parValue));

        emit DecreaseAmountFromMember(acct, parValue, paidPar, blocknumber);
    }

    // ==== Group ====

    function addMemberToGroup(uint40 acct, uint16 group) public onlyKeeper {
        require(group > 0, "ZERO group");
        require(group <= _counterOfGroups + 1, "group OVER FLOW");
        require(_groupNo[acct] == 0, "belongs to another group");

        _groupsList.add(group);

        if (group > _counterOfGroups) _counterOfGroups = group;

        _groupNo[acct] = group;

        _membersOfGroup[group].add(acct);

        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(uint40 acct, uint16 group)
        public
        groupExist(group)
        onlyKeeper
    {
        require(_groupNo[acct] == group, "WRONG group number");

        _membersOfGroup[group].remove(acct);

        if (_membersOfGroup[group].length() == 0) {
            delete _membersOfGroup[group];
            _groupsList.remove(group);
        }

        _groupNo[acct] == 0;

        emit RemoveMemberFromGroup(acct, group);
    }

    function setController(uint16 group) external onlyKeeper groupExist(group) {
        _controller = group;
        emit SetController(group);
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
    function counterOfShares() external view onlyUser returns (uint16) {
        return _counterOfShares;
    }

    function counterOfClasses() external view onlyUser returns (uint8) {
        return _counterOfClasses;
    }

    function regCap() external view onlyUser returns (uint64 par) {
        (par, ) = _ownersEquity.latest();
    }

    function paidCap() external view onlyUser returns (uint64 paid) {
        (, paid) = _ownersEquity.latest();
    }

    function capAtBlock(uint64 blocknumber)
        external
        view
        onlyUser
        returns (uint64 par, uint64 paid)
    {
        (par, paid) = _ownersEquity.getAtBlock(blocknumber);
    }

    function totalVote() external view onlyUser returns (uint64 vote) {
        if (_getSHA().basedOnPar()) (vote, ) = _ownersEquity.latest();
        else (, vote) = _ownersEquity.latest();
    }

    function totalVoteAtBlock(uint64 blocknumber)
        external
        view
        onlyUser
        returns (uint64 vote)
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

    function cleanPar(bytes6 ssn) external view onlyUser returns (uint64) {
        return _shares[ssn].cleanPar;
    }

    function getShare(bytes6 ssn)
        external
        view
        shareExist(ssn)
        onlyUser
        returns (
            bytes32 shareNumber,
            uint64 parValue,
            uint64 paidPar,
            uint32 paidInDeadline,
            uint32 unitPrice,
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

    // ==== MembersRepo ====

    function maxQtyOfMembers() external view onlyUser returns (uint8) {
        return _maxQtyOfMembers;
    }

    function isMember(uint40 acct) public view onlyUser returns (bool) {
        return _members.contains(acct);
    }

    function members() external view onlyUser returns (uint40[]) {
        return _members.valuesToUint40();
    }

    function qtyOfmembersAtBlock(uint64 blockNumber)
        external
        view
        onlyUser
        returns (uint8)
    {
        (uint256 qty, ) = _qtyOfMembers.getAtBlock(blockNumber);
        return (uint8(qty));
    }

    function parInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (uint64 par)
    {
        (par, ) = _votesInHand[acct].latest();
    }

    function paidInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (uint64 paid)
    {
        (, paid) = _votesInHand[acct].latest();
    }

    function voteInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (uint64 vote)
    {
        if (_getSHA().basedOnPar()) (vote, ) = _votesInHand[acct].latest();
        else (, vote) = _votesInHand[acct].latest();
    }

    function votesAtBlock(uint40 acct, uint64 blockNumber)
        external
        view
        onlyUser
        returns (uint64 vote)
    {
        if (_getSHA().basedOnPar())
            (vote, ) = _votesInHand[acct].getAtBlock(blockNumber);
        else (, vote) = _votesInHand[acct].getAtBlock(blockNumber);
    }

    function sharesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        onlyUser
        returns (bytes32[])
    {
        return _sharesInHand[acct].values();
    }

    // ==== Group ====

    function counterOfGroups() external view onlyUser returns (uint16) {
        return _counterOfGroups;
    }

    function controller() external view onlyUser returns (uint16) {
        return _controller;
    }

    function groupNo(uint40 acct) external view onlyUser returns (uint16) {
        return _groupNo[acct];
    }

    function membersOfGroup(uint16 group)
        external
        view
        onlyUser
        returns (uint40[])
    {
        return _membersOfGroup[group].valuesToUint40();
    }

    function isGroup(uint16 group) external view onlyUser returns (bool) {
        return _groupsList.contains(group);
    }

    function groupsList() external view onlyUser returns (uint16[]) {
        return _groupsList.valuesToUint16();
    }
}
