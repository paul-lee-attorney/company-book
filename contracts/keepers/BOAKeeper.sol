/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/interfaces/IAdminSetting.sol";
import "../common/interfaces/IAgreement.sol";
import "../common/interfaces/ISigPage.sol";
import "../common/interfaces/IBookSetting.sol";

import "../books/boh/interfaces/IAlong.sol";

import "../common/config/BOMSetting.sol";
import "../common/config/BOASetting.sol";
import "../common/config/BOSSetting.sol";
import "../common/config/BOHSetting.sol";

import "../common/lib/serialNumber/DealSNParser.sol";
import "../common/lib/serialNumber/ShareSNParser.sol";

import "../common/components/EnumsRepo.sol";

contract BOAKeeper is
    EnumsRepo,
    BOASetting,
    BOHSetting,
    BOMSetting,
    BOSSetting
{
    using DealSNParser for bytes32;
    using ShareSNParser for bytes32;

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
        IBookSetting(body).setBOS(address(_bos));
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

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external {
        address rightholder = shareNumber.shareholder();

        address term = getSHA().getTerm(uint8(TermTitle.TAG_ALONG));

        _execAlongRight(
            rightholder,
            term,
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            execDate
        );
    }

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external {
        address rightholder = IAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        address term = getSHA().getTerm(uint8(TermTitle.DRAG_ALONG));

        _execAlongRight(
            rightholder,
            term,
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            execDate
        );
    }

    function _execAlongRight(
        address rightholder,
        address term,
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) private currentDate(execDate) {
        require(
            !_bom.isProposed(ia) || _bom.votingDeadline(ia) >= now - 15 minutes,
            "MISSED voting deadline"
        );

        address seller = shareNumber.shareholder();

        address drager = IAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        require(msg.sender == rightholder, "msg.sender NOT rightholder");

        require(IAlong(term).isTriggered(ia, sn), "TagAlong NOT triggered");

        require(IAlong(term).isLinked(drager, seller), "NOT linked");

        require(
            IAlong(term).priceCheck(ia, sn, shareNumber),
            "price NOT satisfied"
        );

        // test quota of alongDeal and update mock results
        _boa.addAlongDeal(
            ia,
            IAlong(term).linkRule(_bos.groupNo(drager)),
            shareNumber,
            parValue,
            paidPar
        );

        // suspend voting procedure
        if (_bom.isProposed(ia)) _bom.suspendVoting(ia);

        // add in along deal
        IAgreement(ia).createAlongDeal(
            shareNumber,
            sn.sequenceOfDeal(),
            parValue,
            paidPar,
            execDate
        );
    }

    function acceptTagAlong(
        address ia,
        address drager,
        bytes32 sn
    ) external {
        require(
            _bom.votingDeadline(ia) >= now - 15 minutes,
            "MISSED voting deadline"
        );

        require(msg.sender == sn.buyerOfDeal(), "msg.sender NOT buyer");

        require(
            ISigPage(ia).sigDate(sn.buyerOfDeal()) > 0,
            "pls SIGN the along deal first"
        );

        _boa.acceptAlongDeal(ia, drager, sn);

        if (_boa.stateOfDoc(ia) == 1) _bom.resumeVoting(ia);
    }

    function pushToCoffer(
        bytes32 sn,
        address ia,
        bytes32 hashLock,
        uint256 closingDate
    ) external {
        require(_bom.isPassed(ia), "Motion NOT passed");

        require(_boa.isSubmitted(ia), "Agreement NOT in submitted state");

        address sender = msg.sender;

        if (sn.typeOfDeal() > 1) {
            require(
                sender ==
                    IAgreement(ia)
                        .shareNumberOfDeal(sn.sequenceOfDeal())
                        .shareholder(),
                "NOT seller"
            );

            _checkSHA(_termsForShareTransfer, ia, sn);

            (, , uint256 parValue, , , , ) = IAgreement(ia).getDeal(
                sn.sequenceOfDeal()
            );
            _bos.decreaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
        } else {
            require(sender == getGK(), "NOT GeneralKeeper");
            _checkSHA(_termsForCapitalIncrease, ia, sn);
        }

        IAgreement(ia).clearDealCP(sn.sequenceOfDeal(), hashLock, closingDate);
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
        // require(_boa.isRegistered(ia), "协议  未注册");
        require(_boa.isSubmitted(ia), "Agreement NOT in submitted state");

        (
            ,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            ,
            ,

        ) = IAgreement(ia).getDeal(sn.sequenceOfDeal());

        // address buyer = sn.buyerOfDeal();

        //交易发起人为买方;
        require(sn.buyerOfDeal() == msg.sender, "msg.sender is NOT buyer");

        //验证hashKey, 执行Deal
        IAgreement(ia).closeDeal(sn.sequenceOfDeal(), hashKey);

        bytes32 shareNumber = sn.shareNumberOfDeal(_bos.snList());

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > bytes32(0)) {
            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
            _bos.transferShare(
                shareNumber,
                parValue,
                paidPar,
                sn.buyerOfDeal(),
                closingDate,
                unitPrice
            );
        } else {
            _bos.issueShare(
                sn.buyerOfDeal(),
                sn.classOfDeal(),
                parValue,
                paidPar,
                closingDate, //paidInDeadline
                closingDate, //issueDate
                unitPrice //issuePrice
            );
        }

        if (sn.groupOfBuyer() > 0)
            _bos.addMemberToGroup(sn.buyerOfDeal(), sn.groupOfBuyer());

        _bosCal.updateController(true);
    }

    function revokeDeal(
        bytes32 sn,
        address ia,
        string hashKey
    ) external {
        require(_boa.isRegistered(ia), "IA NOT registered");
        // require(_boa.isSubmitted(ia), "Agreement NOT in submitted state");

        address sender = msg.sender;
        require(
            (sn.typeOfDeal() == 1 && sender == getGK()) ||
                sender ==
                IAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder(),
            "NOT seller or bookeeper"
        );

        IAgreement(ia).revokeDeal(sn.sequenceOfDeal(), hashKey);

        if (sn.typeOfDeal() > 1) {
            (, , uint256 parValue, , , , ) = IAgreement(ia).getDeal(
                sn.sequenceOfDeal()
            );

            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
            _bos.updateShareState(sn.shortShareNumberOfDeal(), 0);
        }
    }
}
