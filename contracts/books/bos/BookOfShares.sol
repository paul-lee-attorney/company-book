/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

pragma experimental ABIEncoderV2;

import "./IBookOfShares.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
// import "../../common/lib/ObjsRepo.sol";
// import "../../common/lib/Checkpoints.sol";
// import "../../common/lib/EnumsRepo.sol";
// import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/MembersRepo.sol";
import "../../common/lib/TopChain.sol";

// import "../../common/access/AccessControl.sol";
// import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/SHASetting.sol";

contract BookOfShares is IBookOfShares, SHASetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using MembersRepo for MembersRepo.GeneralMeeting;

    //公司注册号哈希值（统一社会信用号码的“加盐”哈希值）
    bytes32 private _regNumHash;

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
    //     uint16 class; //股份类别（投资轮次）
    //     uint32 sequence; //顺序编码
    //     uint32 issueDate; //发行日期
    //     uint40 shareholder; //股东编号
    //     uint32 preSN; //来源股票编号索引
    // }

    mapping(uint256 => Share) private _shares;

    // ---- PayInCap Locker ----
    struct Locker {
        uint64 amount; //实缴金额
        bytes32 hashLock; //哈希锁
    }
    // ssn => Locker
    mapping(uint256 => Locker) private _lockers;

    MembersRepo.GeneralMeeting private _gm;

    //##################
    //##   Modifier   ##
    //##################

    modifier notFreezed(uint32 ssn) {
        require(_shares[ssn].state < 4, "BOS.notFreezed: FREEZED share");
        _;
    }

    modifier shareExist(uint32 ssn) {
        require(isShare(ssn), "BOS.shareExist: ssn NOT exist");
        _;
    }

    modifier onlyMember() {
        require(isMember(_msgSender()), "BOS.onlyMember: NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(isMember(acct), "BOS.onlyMember: NOT Member");
        _;
    }

    modifier groupExist(uint16 group) {
        require(isGroup(group), "BOS.onlyMember: NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(bytes32 regNumHash, uint8 max) public {
        _regNumHash = regNumHash;
        _gm.init(max);
    }

    // ==== IssueShare ====

    function issueShare(
        uint40 shareholder,
        uint16 class,
        uint64 paid,
        uint64 par,
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

        _gm.increaseCounterOfShares();

        require(class <= _gm.counterOfClasses(), "class OVER FLOW");
        if (class == _gm.counterOfClasses()) _gm.increaseCounterOfClasses();

        bytes32 shareNumber = _createShareNumber(
            class,
            _gm.counterOfShares(),
            (issueDate == 0) ? uint32(block.timestamp) : issueDate,
            shareholder,
            0
        );

        // 在《股权簿》中添加新股票（签发新的《出资证明书》）
        _issueShare(shareNumber, paid, par, paidInDeadline, issuePrice);

        // 将股票编号加入《股东名册》记载的股东名下
        _addShareToMember(shareNumber.ssn(), shareholder);

        // 增加“认缴出资”和“实缴出资”金额
        _capIncrease(paid, par);
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

        _changeAmtOfMember(
            _shares[ssn].shareNumber.shareholder(),
            amount,
            0,
            false
        );

        // 增加公司的“实缴出资”总额
        _capIncrease(amount, 0);

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
    ) external onlyKeeper {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        require(to > 0, "shareholder userNo is ZERO");
        require(to <= _rc.counterOfUsers(), "shareholder userNo overflow");

        // 判断是否需要新增股东，若需要判断是否超过法定人数上限
        _addMember(to);

        _decreaseShareAmount(ssn, paid, par);

        _gm.increaseCounterOfShares();

        // 在“新股东”名下增加新的股票
        bytes32 shareNumber_1 = _createShareNumber(
            shareNumber.class(),
            _gm.counterOfShares(),
            uint32(block.timestamp),
            to,
            shareNumber.ssn()
        );

        _issueShare(
            shareNumber_1,
            paid,
            par,
            _shares[ssn].paidInDeadline,
            unitPrice
        );

        _addShareToMember(shareNumber_1.ssn(), to);
    }

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external onlyManager(1) {
        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmount(ssn, paid, par);

        // 减少公司“注册资本”和“实缴出资”总额
        _capDecrease(paid, par);
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
        require(share.state < 4, "FREEZED share");
        require(paid <= par, "paid BIGGER than par");

        // 若拟降低的面值金额等于股票面值，则删除相关股票
        if (par == share.par) {
            _removeShareFromMember(ssn, share.shareNumber.shareholder());
            _deregisterShare(ssn);
        } else {
            // 仅调低认缴和实缴金额，保留原股票
            _subAmountFromShare(ssn, paid, par);
            _changeAmtOfMember(
                _shares[ssn].shareNumber.shareholder(),
                paid,
                par,
                true
            );
        }
    }

    // ==== SharesRepo ====

    function _createShareNumber(
        uint16 class,
        uint32 ssn,
        uint32 issueDate,
        uint40 shareholder,
        uint32 preSSN
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, class);
        _sn = _sn.dateToSN(2, ssn);
        _sn = _sn.dateToSN(6, issueDate);
        _sn = _sn.acctToSN(10, shareholder);
        _sn = _sn.dateToSN(15, preSSN);

        sn = _sn.bytesToBytes32();
    }

    function _issueShare(
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint32 paidInDeadline,
        uint32 unitPrice
    ) private {
        uint32 ssn = shareNumber.ssn();

        Share storage share = _shares[ssn];

        share.shareNumber = shareNumber;
        share.par = par;
        share.paid = paid;
        share.cleanPar = paid;
        share.paidInDeadline = paidInDeadline;
        share.unitPrice = unitPrice;

        // _shareNumbersList.add(shareNumber);

        emit IssueShare(shareNumber, par, paid, paidInDeadline, unitPrice);
    }

    function _deregisterShare(uint32 ssn) private {
        bytes32 shareNumber = _shares[ssn].shareNumber;

        delete _shares[ssn];

        // _shareNumbersList.remove(shareNumber);

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

        emit PayInCapital(ssn, amount, paidInDate);
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

        emit SubAmountFromShare(ssn, paid, par);
    }

    function _capIncrease(uint64 paid, uint64 par) private {
        uint64 blocknumber = _gm.changeAmtOfCap(paid, par, false);
        emit CapIncrease(paid, par, blocknumber);
    }

    function _capDecrease(uint64 paid, uint64 par) private {
        uint64 blocknumber = _gm.changeAmtOfCap(paid, par, true);
        emit CapDecrease(paid, par, blocknumber);
    }

    // ==== CleanPar ====

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

    // ==== State & PaidInDeadline ====

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

    function setMaxQtyOfMembers(uint8 max) external onlyManager(1) {
        _gm.setMaxQtyOfMembers(max);
        emit SetMaxQtyOfMembers(max);
    }

    function setAmtBase(bool basedOnPar) external onlyKeeper {
        if (_gm.setAmtBase(basedOnPar)) emit SetAmtBase(basedOnPar);
    }

    function _addMember(uint40 acct) private {
        require(
            _gm.qtyOfMembers() < _gm.maxQtyOfMembers() ||
                _gm.maxQtyOfMembers() == 0,
            "Qty of Members overflow"
        );

        if (_gm.addMember(acct)) emit AddMember(acct, _gm.qtyOfMembers());
    }

    function _addShareToMember(uint32 ssn, uint40 acct) private {
        Share storage share = _shares[ssn];

        if (_gm.addShareToMember(share.shareNumber, acct)) {
            _gm.changeAmtOfMember(
                acct,
                share.paid,
                share.par,
                false
            );
            emit AddShareToMember(share.shareNumber, acct);
        }
    }

    function _removeShareFromMember(uint32 ssn, uint40 acct) private {
        Share storage share = _shares[ssn];

        _changeAmtOfMember(acct, share.paid, share.par, true);

        if (_gm.removeShareFromMember(share.shareNumber, acct)) {
            if (_gm.qtyOfSharesInHand(acct) == 0) _gm.delMember(acct);

            emit RemoveShareFromMember(share.shareNumber, acct);
        }
    }

    function _changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) private {
        if (decrease) {
            require(
                _gm.paidOfMember(acct) > deltaPaid,
                "BOS._changeAmtOfMember: paid amount not enough"
            );
            require(
                _gm.parOfMember(acct) > deltaPar,
                "BOS._changeAmtOfMember: par amount not enough"
            );
        }

        uint64 blocknumber = _gm.changeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            decrease
        );

        emit ChangeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            decrease,
            blocknumber
        );
    }

    function addMemberToGroup(uint40 acct, uint16 group) external onlyKeeper {
        require(
            _gm.groupNo(acct) == 0,
            "BOS.addMemberToGroup: remove acct from group first"
        );

        _gm.removeMemberFromChain(acct);
        _gm.addMemberToGroup(acct, group);

        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(uint40 acct, uint16 group)
        external
        onlyKeeper
    {
        require(group == _gm.groupNo(acct), "BOS.removeMemberFromGroup: Acct is not member of Group");
        _gm.removeMemberFromGroup(acct);
        emit RemoveMemberFromGroup(acct, group);
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    // ==== BookOfShares ====

    function verifyRegNum(string regNum)
        external
        view
        returns (bool)
    {
        return _regNumHash == keccak256(bytes(regNum));
    }

    function maxQtyOfMembers() external view returns (uint8) {
        return _gm.maxQtyOfMembers();
    }

    function counterOfShares() external view returns (uint40) {
        return _gm.counterOfShares();
    }

    function counterOfClasses() external view returns (uint16) {
        return _gm.counterOfClasses();
    }

    function paidCap() external view returns (uint64) {
        return _gm.paidCap();
    }

    function parCap() external view returns (uint64) {
        return _gm.parCap();
    }

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64, uint64)
    {
        return _gm.capAtBlock(blocknumber);
    }

    function totalVotes() external view returns (uint64) {
        return _gm.totalVotes();
    }

    // ==== SharesRepo ====

    function isShare(uint32 ssn) public view returns (bool) {
        return _shares[ssn].shareNumber > bytes32(0);
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
            uint32 unitPrice,
            uint8 state
        )
    {
        Share storage share = _shares[ssn];

        shareNumber = share.shareNumber;
        paid = share.paid;
        par = share.par;
        paidInDeadline = share.paidInDeadline;
        unitPrice = share.unitPrice;
        state = share.state;
    }

    function sharesList() external view returns (bytes32[]) {
        return _gm.sharesList();
    }

    function sharenumberExist(bytes32 sharenumber)
        external
        view
        returns (bool)
    {
        return _gm.sharenumberExist(sharenumber);
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

    function isMember(uint40 acct) public view returns (bool) {
        return _gm.isMember(acct);
    }

    function indexOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint16)
    {
        return _gm.indexOfMember(acct);
    }

    function paidOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 paid)
    {
        paid = _gm.paidOfMember(acct);
    }

    function parOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 par)
    {
        par = _gm.parOfMember(acct);
    }

    function votesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64)
    {
        return _gm.votesInHand(acct);
    }

    function votesAtBlock(uint40 acct, uint64 blocknumber)
        external
        view
        memberExist(acct)
        returns (uint64)
    {
        return _gm.votesAtBlock(acct, blocknumber, _getSHA().basedOnPar());
    }

    function sharesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (bytes32[])
    {
        return _gm.sharesInHand(acct);
    }

    function groupNo(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint16)
    {
        return _gm.groupNo(acct);
    }

    function qtyOfMembers() external view returns (uint16) {
        return _gm.qtyOfMembers();
    }

    function membersList() external view returns (uint40[]) {
        return _gm.membersList();
    }

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        memberExist(acct1)
        memberExist(acct2)
        returns (bool)
    {
        return _gm.affiliated(acct1, acct2);
    }

    // ==== group ====

    function isGroup(uint16 group) public view returns (bool) {
        return _gm.isGroup(group);
    }

    function counterOfGroups() external view returns (uint16 ) {
        return _gm.counterOfGroups();
    }

    function controllor() external view returns (uint40) {
        return _gm.controllor();
    }

    function votesOfController() external view returns (uint64) {
        return _gm.votesOfHead();
    }

    function votesOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint64)
    {
        return _gm.votesOfGroup(group);
    }

    function leaderOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint64)
    {
        return _gm.leaderOfGroup(group);
    }

    function membersOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint40[] memory)
    {
        return _gm.membersOfGroup(group);
    }

    function deepOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint16)
    {
        return _gm.deepOfGroup(group);
    }

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _gm.getSnapshot();
    }
}
