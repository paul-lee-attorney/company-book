/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

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
interface IBookOfShares {
    //##################
    //##    Event     ##
    //##################

    // ==== SharesRepo ====

    event IssueShare(
        bytes32 indexed shareNumber,
        uint64 parValue,
        uint64 paidPar,
        uint32 paidInDeadline,
        uint32 unitPrice
    );

    event PayInCapital(bytes6 indexed ssn, uint64 amount, uint32 paidInDate);

    event SubAmountFromShare(
        bytes6 indexed ssn,
        uint64 parValue,
        uint64 paidPar
    );

    event CapIncrease(
        uint64 parValue,
        uint64 regCap,
        uint64 paidPar,
        uint64 paiInCap,
        uint64 blocknumber
    );

    event CapDecrease(
        uint64 parValue,
        uint64 regCap,
        uint64 paidPar,
        uint64 paidCap,
        uint64 blocknumber
    );

    event DeregisterShare(bytes32 indexed shareNumber);

    event UpdateShareState(bytes6 indexed ssn, uint8 state);

    event UpdatePaidInDeadline(bytes6 indexed ssn, uint32 paidInDeadline);

    event DecreaseCleanPar(bytes6 ssn, uint64 parValue);

    event IncreaseCleanPar(bytes6 ssn, uint64 parValue);

    event PledgeShare(bytes6 indexed ssn, uint64 parValue);

    // ==== MembersRepo ====

    event SetMaxQtyOfMembers(uint8 max);

    event AddMember(uint40 indexed acct, uint8 qtyOfMembers);

    event RemoveMember(uint40 indexed acct, uint8 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sn, uint40 acct);

    event RemoveShareFromMember(bytes32 indexed sn, uint40 acct);

    event IncreaseAmountToMember(
        uint40 indexed acct,
        uint64 parValue,
        uint64 paidPar,
        uint64 blocknumber
    );

    event DecreaseAmountFromMember(
        uint40 indexed acct,
        uint64 parValue,
        uint64 paidPar,
        uint64 blocknumber
    );

    // ==== Group ====

    event AddMemberToGroup(uint40 acct, uint16 groupNo);

    event RemoveMemberFromGroup(uint40 acct, uint16 groupNo);

    event SetController(uint16 groupNo);

    //##################
    //##    写接口    ##
    //##################

    /// @notice 初始化 超级管理员 账户地址，设定 公司股东人数上限， 设定 公司注册号哈希值
    /// @param regNumHash - 公司注册号哈希值
    /// @param maxQtyOfMembers - 公司股东人数上限（根据法定最多股东人数设定）
    //    constructor(bytes32 regNumHash, uint8 maxQtyOfMembers) ;

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
        uint64 parValue,
        uint64 paidPar,
        uint32 paidInDeadline,
        uint32 issueDate,
        uint32 issuePrice
    ) external;

    /// @notice 在已经发行的股票项下，实缴出资
    /// @param ssn - 股票短号
    /// @param amount - 实缴出资金额（单位“分”）
    /// @param paidInDate - 实缴出资日期（妙计时间戳）
    function payInCapital(
        bytes6 ssn,
        uint64 amount,
        uint32 paidInDate
    ) external;

    /// @notice 先减少原股票金额（金额降低至“0”则删除），再发行新股票
    /// @param ssn - 股票短号
    /// @param parValue - 股票面值（认缴出资金额）
    /// @param paidPar - 转让的实缴金额（实缴出资金额）
    /// @param to - 受让方账户地址
    /// @param unitPrice - 转让价格（可用于判断“优先权”等条款，公链应用可设定为“1”）
    function transferShare(
        bytes6 ssn,
        uint64 parValue,
        uint64 paidPar,
        uint40 to,
        uint32 unitPrice
    ) external;

    /// @param ssn 拟减资的股票短号
    /// @param parValue 拟减少的认缴出资金额（单位“分”）
    /// @param paidPar 拟减少的实缴出资金额（单位“分”）
    function decreaseCapital(
        bytes6 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external;

    // ==== SharesRepo ====

    function decreaseCleanPar(bytes6 ssn, uint64 parValue) external;

    function increaseCleanPar(bytes6 ssn, uint64 parValue) external;

    function updateShareState(bytes6 ssn, uint8 state) external;

    function updatePaidInDeadline(bytes6 ssn, uint32 paidInDeadline) external;

    // ==== GroupsRepo ====

    function addMemberToGroup(uint40 acct, uint16 group) external;

    function removeMemberFromGroup(uint40 acct, uint16 group) external;

    function setController(uint16 group) external;

    // ==== MembersRepo ====

    function setMaxQtyOfMembers(uint8 max) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    /// @notice 输入 公司注册号哈希值 验证与 regNumHash 一致性，
    /// 从而确认《股权簿》的公司主体身份
    /// @dev 仅 股东 有权操作
    /// @param regNum - 公司注册号
    /// @return true - 认证通过 ; false - 认证失败
    function verifyRegNum(string regNum) external view returns (bool);

    // ==== SharesRepo ====

    function counterOfShares() external view returns (uint16);

    function counterOfClasses() external view returns (uint8);

    function regCap() external view returns (uint64);

    function paidCap() external view returns (uint64);

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 par, uint64 paid);

    function totalVote() external view returns (uint64 vote);

    function totalVoteAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 vote);

    function isShare(bytes6 ssn) external view returns (bool);

    function snList() external view returns (bytes32[]);

    function cleanPar(bytes6 ssn) external view returns (uint64);

    function getShare(bytes6 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint64 parValue,
            uint64 paidPar,
            uint32 paidInDeadline,
            uint32 unitPrice,
            uint8 state
        );

    // ========== GroupsRepo ==============

    function counterOfGroups() external view returns (uint16);

    function controller() external view returns (uint16);

    function groupNo(uint40 acct) external view returns (uint16);

    function membersOfGroup(uint16 group) external view returns (uint40[]);

    function isGroup(uint16 group) external view returns (bool);

    function groupsList() external view returns (uint16[]);

    // ========== MembersRepo ==============

    function maxQtyOfMembers() external view returns (uint8);

    function isMember(uint40 acct) external view returns (bool);

    function members() external view returns (uint40[]);

    function qtyOfMembersAtBlock(uint64 blockNumber)
        external
        view
        returns (uint64);

    function parInHand(uint40 acct) external view returns (uint64);

    function paidInHand(uint40 acct) external view returns (uint64);

    function voteInHand(uint40 acct) external view returns (uint64 vote);

    function votesAtBlock(uint40 acct, uint64 blockNumber)
        external
        view
        returns (uint64 vote);

    function sharesInHand(uint40 acct) external view returns (bytes32[]);
}
