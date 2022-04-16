/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/interfaces/IAdminSetting.sol";
import "../common/interfaces/IBOSSetting.sol";
import "../common/interfaces/IAgreement.sol";
import "../common/interfaces/ISigPage.sol";

import "../common/config/BOMSetting.sol";
import "../common/config/BOASetting.sol";
import "../common/config/BOSSetting.sol";
import "../common/config/BOHSetting.sol";

import "../common/lib/serialNumber/DealSNParser.sol";

import "../common/components/EnumsRepo.sol";

contract BOAKeeper is
    EnumsRepo,
    BOMSetting,
    BOASetting,
    BOHSetting,
    BOSSetting
{
    using DealSNParser for bytes32;

    TermTitle[] private _termsForCapitalIncrease = [
        TermTitle.ANTI_DILUTION,
        TermTitle.PRE_EMPTIVE
    ];

    TermTitle[] private _termsForShareTransfer = [
        TermTitle.LOCK_UP,
        TermTitle.FIRST_REFUSAL,
        TermTitle.TAG_ALONG
    ];

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier beEstablished(address body) {
        require(ISigPage(body).isEstablished(), "Doc NOT Established");
        _;
    }

    modifier notEstablished(address body) {
        require(!ISigPage(body).isEstablished(), "Doc ALREADY Established");
        _;
    }

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "NOT Admin of Doc"
        );
        _;
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
        // ISigPage(body).submitDoc();
        IAdminSetting(body).abandonAdmin();
    }

    function pushToCoffer(
        bytes32 sn,
        address ia,
        bytes32 hashLock,
        uint256 closingDate
    ) external {
        require(_bom.isPassed(ia), "Motion NOT passed");

        uint8 typeOfDeal = sn.typeOfDeal();
        bytes32 shareNumber = sn.shareNumber(_bos.snList());
        address seller = sn.seller(_bos.snList());

        //交易发起人为卖方或簿记管理人(Bookeeper);
        address sender = msg.sender;
        require(
            (typeOfDeal == 1 && sender == getBookeeper()) || sender == seller,
            "NOT seller or Bookeeper"
        );

        //SHA校验
        if (typeOfDeal > 1) {
            _checkSHA(_termsForShareTransfer, ia, sn);

            (, uint256 parOfDeal, , , , ) = IAgreement(ia).getDeal(sn);
            _bos.decreaseCleanPar(shareNumber, parOfDeal);
        } else _checkSHA(_termsForCapitalIncrease, ia, sn);

        IAgreement(ia).clearDealCP(sn, hashLock, closingDate);
    }

    function _checkSHA(
        TermTitle[] terms,
        address ia,
        bytes32 sn
    ) private {
        uint256 len = terms.length;
        for (uint256 i = 0; i < len; i++)
            if (getSHA().hasTitle(uint8(terms[i])))
                require(
                    getSHA().termIsExempted(uint8(terms[i]), ia, sn),
                    "SHA check failed"
                );
    }

    function closeDeal(
        bytes32 sn,
        address ia,
        uint32 closingDate,
        string hashKey
    ) external currentDate(closingDate) {
        //校验ia是否注册;
        require(_boa.isRegistered(ia), "协议  未注册");

        (
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            ,
            ,

        ) = IAgreement(ia).getDeal(sn);

        // address buyer = sn.buyer();

        //交易发起人为买方;
        require(sn.buyer() == msg.sender, "仅 买方  可调用");

        //验证hashKey, 执行Deal
        IAgreement(ia).closeDeal(sn, hashKey);

        bytes32 shareNumber = sn.shareNumber(_bos.snList());

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > bytes32(0)) {
            _bos.increaseCleanPar(shareNumber, parValue);
            _bos.transferShare(
                shareNumber,
                parValue,
                paidPar,
                sn.buyer(),
                closingDate,
                unitPrice
            );
        } else {
            _bos.issueShare(
                sn.buyer(),
                sn.classOfDeal(),
                parValue,
                paidPar,
                closingDate, //paidInDeadline
                closingDate, //issueDate
                unitPrice //issuePrice
            );
        }
    }

    function revokeDeal(
        bytes32 sn,
        address ia,
        string hashKey
    ) external {
        require(_boa.isRegistered(ia), "IA NOT registered");

        address sender = msg.sender;
        require(
            (sn.typeOfDeal() == 1 && sender == getBookeeper()) ||
                sender == sn.seller(_bos.snList()),
            "NOT seller or bookeeper"
        );

        IAgreement(ia).revokeDeal(sn, hashKey);

        if (sn.typeOfDeal() > 1)
            _bos.updateShareState(sn.shareNumber(_bos.snList()), 0);
    }
}
