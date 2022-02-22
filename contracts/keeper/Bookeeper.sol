/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/AdminSetting.sol";

import "../interfaces/IBOSSetting.sol";
// import "../interfaces/IBOMSetting.sol";

import "../config/BOSSetting.sol";
import "../config/BOHSetting.sol";
import "../config/BOASetting.sol";
import "../config/BOMSetting.sol";

import "../interfaces/IAgreement.sol";
import "../interfaces/ISigPage.sol";

import "../sha/interfaces/IVotingRules.sol";

import "../common/EnumsRepo.sol";

contract Bookeeper is
    EnumsRepo,
    BOSSetting,
    BOASetting,
    BOHSetting,
    BOMSetting
{
    address[18] private _termsTemplate;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ################
    // ##   Events   ##
    // ################

    event AddTemplate(uint8 title, address add);

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier beEstablished(address body) {
        require(ISigPage(body).isEstablished(), "文件 尚未 成立");
        _;
    }

    modifier notEstablished(address body) {
        require(ISigPage(body).isEstablished(), "文件 尚未 成立");
        _;
    }

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "只有 Admin 可操作"
        );
        _;
    }

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(msg.sender), "只有 当事方 可操作");
        _;
    }

    // ###############
    // ##   Admin   ##
    // ###############

    function setKeeperOfBook(address book, address bookeeper)
        external
        onlyBookeeper
    {
        IAdminSetting(book).setBookeeper(bookeeper);
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(uint8 title, address add) external onlyAdmin {
        _termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function getTermTemplate(uint8 title)
        external
        view
        onlyStakeholders
        returns (address)
    {
        return _termsTemplate[title];
    }

    function createSHA(uint8 docType)
        external
        onlyMember
        returns (address body)
    {
        body = _boh.createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IShareholdersAgreement(body).setTermsTemplate(_termsTemplate);
        IShareholdersAgreement(body).setBOS(address(_bos));
        IShareholdersAgreement(body).setBOM(address(_bom));
    }

    function removeSHA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        _boh.removeDoc(body);
    }

    function submitSHA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        _boh.submitDoc(body, docHash);
        IAdminSetting(body).abandonAdmin();
    }

    // ###################
    // ##   Agreement   ##
    // ###################

    function createIA(uint8 docType)
        external
        onlyMember
        returns (address body)
    {
        body = _boa.createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IBOSSetting(body).setBOS(address(_bos));
    }

    function removeIA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        _boa.removeDoc(body);
    }

    function submitIA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        _boa.submitDoc(body, docHash);
        IAdminSetting(body).abandonAdmin();
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia) external onlyPartyOf(ia) {
        uint8 votingDays = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        ).getVotingDays();

        _bom.proposeMotion(ia, votingDays);
    }

    // ##############
    // ##   Deal   ##
    // ##############

    function pushToCoffer(
        uint8 sn,
        address ia,
        bytes32 hashLock,
        uint256 closingDate
    ) external returns (bool flag, uint8[] triggers) {
        //校验IA是否表决通过
        require(_bom.isPassed(ia), "动议表决 未通过");

        // Agreement.Deal memory deal = IAgreement(ia).getDeal(sn);

        (
            uint256 shareNumber,
            ,
            address seller,
            ,
            ,
            ,
            ,
            ,
            uint8 typeOfDeal,
            ,

        ) = IAgreement(ia).getDeal(sn);

        //交易发起人为卖方或簿记管理人(Bookeeper);
        address sender = msg.sender;
        require(
            (typeOfDeal == 1 && sender == getBookeeper()) || sender == seller,
            "无权操作"
        );

        //SHA校验
        (flag, triggers) = getSHA().dealIsExempted(ia, sn, typeOfDeal);

        if (flag) {
            IAgreement(ia).clearDealCP(sn, hashLock, closingDate);
            if (typeOfDeal > 1) _bos.updateShareState(shareNumber, 2);
        }
    }

    function closeDeal(
        uint8 sn,
        address ia,
        bytes hashKey
    ) external returns (bool flag) {
        //校验ia是否注册；
        require(_boa.isRegistered(ia), "协议  未注册");

        //获取Deal
        // Agreement.Deal memory deal = IAgreement(ia).getDeal(sn);
        (
            uint256 shareNumber,
            uint8 class,
            ,
            address buyer,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidInAmount,
            ,
            ,
            ,

        ) = IAgreement(ia).getDeal(sn);

        //交易发起人为买方;
        require(buyer == msg.sender, "仅 买方  可调用");

        //验证hashKey, 执行Deal
        IAgreement(ia).closeDeal(sn, hashKey);

        uint256 closingDate = now;
        uint256 paidInDate;

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > 0) {
            _bos.updateShareState(shareNumber, 0);
            _bos.transferShare(
                shareNumber,
                parValue,
                paidInAmount,
                buyer,
                closingDate,
                unitPrice
            );
        } else {
            if (paidInAmount > 0) paidInDate = closingDate;

            _bos.issueShare(
                buyer,
                class,
                parValue,
                paidInAmount,
                closingDate, //paidInDeadline
                closingDate, //issueDate
                unitPrice //issuePrice
            );
        }

        flag = true;
    }
}
