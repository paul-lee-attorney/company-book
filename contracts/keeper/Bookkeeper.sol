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

contract Bookkeeper is
    EnumsRepo,
    BOSSetting,
    BOASetting,
    BOHSetting,
    BOMSetting
{
    address[18] private _termsTemplate;

    constructor (address bookkeeper) public {
        init(msg.sender, bookkeeper);
    }

    // ################
    // ##   Events   ##
    // ################

    event AddTemplate(uint8 title, address add);

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyMember() {
        require(getBOS().isMember(msg.sender), "仅 股东 可操作");
        _;
    }

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
        body = getBOH().createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IShareholdersAgreement(body).setTermsTemplate(_termsTemplate);
        // IBOSSetting(body).setBOS(address(getBOS()));
        // IBOMSetting(body).setBOM(address(getBOM()));
    }

    function removeSHA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        getBOH().removeDoc(body);
    }

    function submitSHA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        getBOH().submitDoc(body, docHash);
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
        body = getBOA().createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IBOSSetting(body).setBOS(address(getBOS()));
    }

    function removeIA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        getBOA().removeDoc(body);
    }

    function submitIA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        getBOA().submitDoc(body, docHash);
        IAdminSetting(body).abandonAdmin();
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia) external onlyPartyOf(ia) {
        uint8 votingDays = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        ).getVotingDays();

        getBOM().proposeMotion(ia, votingDays);
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
        require(getBOM().isPassed(ia), "动议表决 未通过");

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

        //交易发起人为卖方或簿记管理人(Bookkeeper);
        address sender = msg.sender;
        require(
            (typeOfDeal == 1 && sender == getBookkeeper()) || sender == seller,
            "无权操作"
        );

        //SHA校验
        (flag, triggers) = getSHA().dealIsExempted(ia, sn, typeOfDeal);

        if (flag) {
            IAgreement(ia).clearDealCP(sn, hashLock, closingDate);
            if (typeOfDeal > 1) getBOS().updateShareState(shareNumber, 2);
        }
    }

    function closeDeal(
        uint8 sn,
        address ia,
        bytes32 hashKey
    ) external returns (bool flag) {
        //校验ia是否注册；
        require(getBOA().isRegistered(ia), "协议  未注册");

        //获取Deal
        // Agreement.Deal memory deal = IAgreement(ia).getDeal(sn);
        (
            uint256 shareNumber,
            uint8 class,
            address seller,
            address buyer,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidInAmount,
            ,
            uint8 typeOfDeal,
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
            getBOS().updateShareState(shareNumber, 0);
            getBOS().transferShare(
                shareNumber,
                parValue,
                paidInAmount,
                buyer,
                closingDate,
                unitPrice
            );
        } else {
            if (paidInAmount > 0) paidInDate = closingDate;

            getBOS().issueShare(
                buyer,
                class,
                parValue,
                closingDate, //paidInDeadline
                closingDate, //issueDate
                unitPrice, //issuePrice
                closingDate, //obtainedDate
                unitPrice, //obtainedPrice
                paidInDate,
                paidInAmount,
                0 //state
            );
        }

        flag = true;
    }
}
