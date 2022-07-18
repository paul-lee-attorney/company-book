/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./MembersRepo.sol";
import "../../common/lib/SNParser.sol";

import "./IBookOfShares.sol";

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
    using SNParser for bytes32;

    //公司注册号哈希值（统一社会信用号码的“加盐”哈希值）
    bytes32 private _regNumHash;

    /// @notice 初始化 超级管理员 账户地址，设定 公司股东人数上限， 设定 公司注册号哈希值
    /// @param regNumHash - 公司注册号哈希值
    /// @param maxQtyOfMembers - 公司股东人数上限（根据法定最多股东人数设定）
    constructor(bytes32 regNumHash, uint8 maxQtyOfMembers)
        public
        // address bookeeper
        MembersRepo(maxQtyOfMembers)
    {
        _regNumHash = regNumHash;
        // init(msg.sender, bookeeper);
    }

    /// @param shareholder - 股东账户地址
    /// @param class - 股份类别（天使轮、A轮、B轮...）
    /// @param parValue - 股份面值（认缴出资金额，单位为“分”）
    /// @param paidPar - 实缴金额（实缴出资金额，单位为“分”）
    /// @param paidInDeadline - 出资期限（秒计时间戳）
    /// @param issueDate - 签发日期（秒计时间戳）
    /// @param issuePrice - 发行价格（用于判断“反稀释”等价格相关《股东协议》条款,
    /// 公链应用时，出于保密考虑可设置为“1”）
    function issueShare(
        uint40 shareholder,
        uint8 class,
        uint256 parValue,
        uint256 paidPar,
        uint32 paidInDeadline,
        uint32 issueDate,
        uint256 issuePrice
    ) external onlyKeeper {
        require(shareholder != address(0), "shareholder address is ZERO");
        require(issueDate <= now + 15 minutes, "issueDate NOT a PAST time");
        require(
            issueDate <= paidInDeadline,
            "issueDate LATER than paidInDeadline"
        );

        require(paidPar <= parValue, "paidPar BIGGER than parValue");

        // 判断是否需要添加新股东，若添加是否会超过法定人数上限
        _addMember(shareholder, uint64(parValue));

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

    /// @notice 在已经发行的股票项下，实缴出资
    /// @param ssn - 股票短号
    /// @param amount - 实缴出资金额（单位“分”）
    /// @param paidInDate - 实缴出资日期（妙计时间戳）
    function payInCapital(
        bytes6 ssn,
        uint256 amount,
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

    /// @notice 先减少原股票金额（金额降低至“0”则删除），再发行新股票
    /// @param ssn - 股票短号
    /// @param parValue - 股票面值（认缴出资金额）
    /// @param paidPar - 转让的实缴金额（实缴出资金额）
    /// @param to - 受让方账户地址
    /// @param unitPrice - 转让价格（可用于判断“优先权”等条款，公链应用可设定为“1”）
    function transferShare(
        bytes6 ssn,
        uint256 parValue,
        uint256 paidPar,
        uint40 to,
        uint256 unitPrice
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

    /// @param ssn 拟减资的股票短号
    /// @param parValue 拟减少的认缴出资金额（单位“分”）
    /// @param paidPar 拟减少的实缴出资金额（单位“分”）
    function decreaseCapital(
        bytes6 ssn,
        uint256 parValue,
        uint256 paidPar
    ) external onlyKeeper {
        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmount(ssn, parValue, paidPar);

        // 减少公司“注册资本”和“实缴出资”总额
        _capDecrease(parValue, paidPar);
    }

    /// @param ssn 拟减资的股票编号
    /// @param parValue 拟减少的认缴出资金额（单位“分”）
    /// @param paidPar 拟减少的实缴出资金额（单位“分”）
    function _decreaseShareAmount(
        bytes6 ssn,
        uint256 parValue,
        uint256 paidPar
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

    // ##################
    // ##   查询接口   ##
    // ##################

    /// @notice 输入 公司注册号哈希值 验证与 regNumHash 一致性，
    /// 从而确认《股权簿》的公司主体身份
    /// @dev 仅 股东 有权操作
    /// @param regNum - 公司注册号
    /// @return true - 认证通过 ; false - 认证失败
    function verifyRegNum(string regNum)
        external
        view
        onlyMember
        returns (bool)
    {
        return _regNumHash == keccak256(bytes(regNum));
    }
}
