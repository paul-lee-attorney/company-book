/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";
import "../lib/SafeMath.sol";
import "./MembersRepo.sol";

/// @author 李力@北京市竞天公诚律师事务所
/// @notice 包括《股权登记簿》和《股东名册》两个组成部分。
/// (1) 《股权登记簿》可适用于“有限责任公司”和“股份有限公司”，
/// 在注释中被简称为《股票簿》，相当于公司股份的簿记内档，体现股票（或《出资证明书》）的记载内容。
/// 根据我国《公司法》，可通过《公司章程》确认本智能合约记载的电子数据的法律效力，
/// 使得《股权登记簿》产生设立、变更、撤销股权的直接法律效力（工商登记仅为对抗效力）。
/// 进而以区块链技术，在股东和公司之间搭建专用联盟链，记载《股东名册》和《股权簿记》，
/// 实现公司股权“上链”，通过智能合约实现“自动控制”和“自动化交易”。
/// (2) 《股东名册》按《公司法》逻辑设计，可更新、查询股东持有的股票（或《出资证明回书》）构成、
/// 认缴出资总额、实缴出资总额等信息；
/// (3) 簿记管理人，可设置为外部账户，由特定自然人受托管理（如外聘律师或会计师），
/// 也可以设置为智能合约账户，写入更为复杂的商务、法律逻辑，
/// 从而实现增资、股转等交易的“自动控制”和“原子化”交割;
/// (4) 如果将《公司章程》、《股东协议》等商业、法律逻辑加入,
/// 即可实现对股东权益的直接保护、对股权权益的去中心化、自动化控制。
/// (5) 本系统按照全部“匿名化”逻辑设置，仅“超级管理员”、“簿记管理人”和“股东”等利害关系方
/// 知悉本系统及各账户的主体身份，外部人员无法得知相关地址与主体之间的映射关系。
/// 而且，公司股权簿记信息（发行价、交易价除外），依法需要在“企业信用登记系统”（工商系统）及时对外公示，
/// 因此，本系统即便在公链环境下使用，也并不会给公司、股东带来泄密、数据安全受损的问题。
/// 出于后续开发考虑，本系统预留了各类“交易价格”属性，此类信息不建议在公链或许可链等环境下直接以明文披露，
/// 否则将给相关的利害关系方，造成不可估量的经济损失及负面影响。
contract BookOfShares is IBookOfShares, MembersRepo {
    using SafeMath for uint256;
    using SafeMath for uint8;

    //公司注册号哈希值（统一社会信用号码的“加盐”哈希值）
    bytes32 private _regNumHash;

    //股权序列号计数器（2**16-1 应该足够计数，因此可考虑uint16）
    uint256 private _counterOfShare;

    //类别序列号计数器
    uint8 private _counterOfClass;

    /// @notice 初始化 超级管理员 账户地址，设定 公司股东人数上限， 设定 公司注册号哈希值
    /// @param regNumHash - 公司注册号哈希值
    /// @param maxQtyOfMembers - 公司股东人数上限（根据法定最多股东人数设定）
    constructor(
        bytes32 regNumHash,
        uint8 maxQtyOfMembers,
        address bookeeper
    ) public MembersRepo(maxQtyOfMembers) {
        _regNumHash = regNumHash;
        init(msg.sender, bookeeper);
    }

    /// @param shareholder - 股东账户地址
    /// @param class - 股份类别（天使轮、A轮、B轮...）
    /// @param parValue - 股份面值（认缴出资金额，单位为“分”）
    /// @param paidInDeadline - 出资期限（秒计时间戳）
    /// @param issueDate - 签发日期（秒计时间戳）
    /// @param issuePrice - 发行价格（用于判断“反稀释”等价格相关《股东协议》条款,
    /// 公链应用时，出于保密考虑可设置为“1”）
    /// @param obtainedDate - 取得日期（秒计时间戳，受让取得时，与签发日期不同）
    /// @param obtainedPrice - 取得价格（受让取得时，与发行价格不同，
    //// 可用于计算“IRR”、回购收益率等目的，公链应用时，出于保密考虑可设置为“1”）
    /// @param paidInDate - 实缴日期（秒计时间戳）
    /// @param paidInAmount - 实缴金额（实缴出资金额，单位为“分”）
    /// @param state - 股票状态（为质押、查封、信托等特殊安排预留状态变量）
    function issueShare(
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
    ) external onlyBookeeper {
        // 判断是否需要添加新股东，若添加是否会超过法定人数上限
        _addMember(shareholder);

        // 股票编号计数器顺加“1”
        _counterOfShare = _counterOfShare.add(1);

        require(class <= _counterOfClass, "股份类别超限");
        if (class == _counterOfClass) _counterOfClass = _counterOfClass.add8(1);

        // 向《股东名册》的“股东”名下添加新股票
        _addShareToMember(shareholder, _counterOfShare, parValue, paidInAmount);

        // 在《股权簿》中添加新股票（签发新的《出资证明书》）
        _issueShare(
            _counterOfShare,
            shareholder,
            class,
            parValue,
            paidInDeadline,
            issueDate,
            issuePrice,
            obtainedDate,
            obtainedPrice,
            paidInDate,
            paidInAmount,
            state
        );

        // 增加“认缴出资”和“实缴出资”金额
        _capIncrease(parValue, paidInAmount);
    }

    /// @notice 在已经发行的股票项下，实缴出资
    /// @param shareNumber - 股票编号
    /// @param amount - 实缴出资金额（单位“分”）
    /// @param paidInDate - 实缴出资日期（妙计时间戳）
    function payInCapital(
        uint256 shareNumber,
        uint256 amount,
        uint256 paidInDate
    ) external onlyBookeeper {
        (address shareholder, , , , , , , , , , ) = _getShare(shareNumber);

        // 向“股东”名下增加“实缴出资”金额
        _payInCapitalToMember(shareholder, amount);

        // 增加“股票”项下实缴出资金额
        _payInCapital(shareNumber, amount, paidInDate);

        // 增加公司的“实缴出资”总额
        _capIncrease(0, amount);
    }

    /// @notice 先减少原股票金额（金额降低至“0”则删除），再发行新股票
    /// @param shareNumber - 股票编号
    /// @param parValue - 股票面值（认缴出资金额）
    /// @param paidInAmount - 转让的实缴金额（实缴出资金额）
    /// @param to - 受让方账户地址
    /// @param closingDate - 交割日（秒计时间戳）
    /// @param unitPrice - 转让价格（可用于判断“优先权”等条款，公链应用可设定为“1”）
    function transferShare(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount,
        address to,
        uint256 closingDate,
        uint256 unitPrice
    ) external onlyNormal(shareNumber) onlyBookeeper {
        // 减少拟出让股票认缴和实缴金额
        _decreaseShareAmount(shareNumber, parValue, paidInAmount);

        // 判断是否需要新增股东，若需要判断是否超过法定人数上限
        _addMember(to);

        _counterOfShare = _counterOfShare.add(1);

        // 在“股东”名下增加新的股票
        _addShareToMember(to, _counterOfShare, parValue, paidInAmount);

        // 发行新股票
        _splitShare(
            shareNumber,
            _counterOfShare,
            to,
            parValue,
            closingDate,
            unitPrice,
            paidInAmount
        );
    }

    /// @param shareNumber 拟减资的股票编号
    /// @param parValue 拟减少的认缴出资金额（单位“分”）
    /// @param paidInAmount 拟减少的实缴出资金额（单位“分”）
    function decreaseCapital(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) external onlyBookeeper {
        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmount(shareNumber, parValue, paidInAmount);

        // 减少公司“注册资本”和“实缴出资”总额
        _capDecrease(parValue, paidInAmount);
    }

    /// @param shareNumber 拟减资的股票编号
    /// @param parValue 拟减少的认缴出资金额（单位“分”）
    /// @param paidInAmount 拟减少的实缴出资金额（单位“分”）
    function _decreaseShareAmount(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) private onlyNormal(shareNumber) onlyBookeeper {
        (
            address shareholder,
            ,
            uint256 orgParValue,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 orgPaidInAmt,

        ) = _getShare(shareNumber);

        require(
            parValue > 0 && parValue <= orgParValue,
            "拟转让 “认缴出资” 溢出或标的股权不存在"
        );

        // 若拟降低的面值金额等于股票面值，则删除相关股票
        if (parValue == orgParValue) {
            _removeShareFromMember(
                shareholder,
                shareNumber,
                orgParValue,
                orgPaidInAmt
            );
            _deregisterShare(shareNumber);
        } else {
            // 仅调低认缴和实缴金额，保留原股票
            _subAmountFromMember(shareholder, parValue, paidInAmount);
            _subAmountFromShare(shareNumber, parValue, paidInAmount);
        }
    }

    /// @param shareNumber - 股票编号
    /// @param state - 股票状态（0：正常，1：出质，2：查封，3：已设定信托，4：代持）
    function updateShareState(uint256 shareNumber, uint8 state)
        external
        onlyBookeeper
    {
        _updateShareState(shareNumber, state);
    }

    /// @param shareNumber - 股票编号
    /// @param paidInDeadline - 实缴出资期限
    function updatePaidInDeadline(uint256 shareNumber, uint256 paidInDeadline)
        external
        onlyBookeeper
    {
        _updatePaidInDeadline(shareNumber, paidInDeadline);
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    /// @notice 输入 公司注册号哈希值 验证与 regNumHash 一致性，
    /// 从而确认《股权簿》的公司主体身份
    /// @dev 仅 股东 有权操作
    /// @param regNumHash - 公司注册号哈希值
    /// @return true - 认证通过 ; false - 认证失败
    function verifyRegNum(bytes32 regNumHash)
        external
        view
        onlyMember
        returns (bool)
    {
        return _regNumHash == regNumHash;
    }

    /// @return 股票序列号计数器当前值
    function getCounterOfShare() external view returns (uint256) {
        return _counterOfShare;
    }

    /// @return 类别序列号计数器当前值
    function getCounterOfClass() external view returns (uint8) {
        return _counterOfClass;
    }

    function shareExist(uint256 shareNumber) external view returns (bool) {
        return _shareExist(shareNumber);
    }

    function getShare(uint256 shareNumber)
        external
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
        return _getShare(shareNumber);
    }

    function getRegCap() external view returns (uint256) {
        return _getRegCap();
    }

    function getPaidInCap() external view returns (uint256) {
        return _getPaidInCap();
    }

    function getShareNumberList() external view returns (uint256[]) {
        return _getShareNumberList();
    }

    function getQtyOfShares() external view returns (uint256) {
        return _getQtyOfShares();
    }

    function isMember(address acct) external view returns (bool) {
        return _isMember(acct);
    }

    function getMember(address acct)
        external
        view
        returns (
            uint256[] sharesInHand,
            uint256 regCap,
            uint256 paidInCap
        )
    {
        return _getMember(acct);
    }

    function getMemberList() external view returns (address[] memberAcctList) {
        return _getMemberList();
    }

    function getQtyOfMembers() external view returns (uint256 qtyOfMembers) {
        return _getQtyOfMembers();
    }

    function getClassMembers(uint8 class)
        external
        view
        returns (address[] classMembers)
    {
        return _getClassMembers(class);
    }

    function getClassShares(uint8 class)
        external
        view
        returns (uint256[] classShares)
    {
        return _getClassShares(class);
    }
}
