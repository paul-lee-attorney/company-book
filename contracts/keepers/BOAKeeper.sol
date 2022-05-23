/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/access/interfaces/IRoles.sol";
import "../common/access/interfaces/IAccessControl.sol";

import "../common/components/interfaces/ISigPage.sol";
import "../common/components/EnumsRepo.sol";
import "../common/utils/Context.sol";

import "../books/boa/interfaces/IAgreement.sol";
import "../books/boh/terms/interfaces/IAlongs.sol";
import "../books/boh/terms/interfaces/IFirstRefusal.sol";

import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";

contract BOAKeeper is
    EnumsRepo,
    BOASetting,
    SHASetting,
    BOMSetting,
    BOSSetting,
    Context
{
    using SNParser for bytes32;

    TermTitle[] private _termsForCapitalIncrease = [
        TermTitle.ANTI_DILUTION,
        TermTitle.FIRST_REFUSAL
    ];

    TermTitle[] private _termsForShareTransfer = [
        TermTitle.LOCK_UP,
        TermTitle.FIRST_REFUSAL,
        TermTitle.TAG_ALONG
    ];

    // constructor(address bookeeper) public {
    //     init(msg.sender, bookeeper);
    // }

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

    modifier onlyOwnerOf(address body) {
        require(
            IAccessControl(body).getOwner() == _bridgedMsgSender,
            "NOT Admin of Doc"
        );
        _;
    }

    // ###################
    // ##   Agreement   ##
    // ###################

    function createIA(uint8 docType) external onlyDirectKeeper {
        require(_bos.isMember(_bridgedMsgSender), "msgSender not MEMBER");

        address body = _boa.createDoc(docType);

        IAccessControl(body).init(
            _rc.userNo(_bridgedMsgSender),
            _rc.userNo(this),
            address(_rc)
        );
        _clearMsgSender();

        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setAgrmtCal(address(_agrmtCal));

        _copyRoleTo(body, KEEPERS);
    }

    function removeIA(address body)
        external
        onlyDirectKeeper
        onlyOwnerOf(body)
        notEstablished(body)
    {
        _clearMsgSender();

        _boa.removeDoc(body);
        IAgreement(body).kill();
    }

    function submitIA(
        address body,
        uint32 submitDate,
        bytes32 docHash
    ) external onlyDirectKeeper onlyOwnerOf(body) beEstablished(body) {
        _boa.submitIA(body, submitDate, docHash, _bridgedMsgSender);
        _clearMsgSender();

        IAccessControl(body).abandonOwnership();
    }

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external onlyDirectKeeper {
        uint32 rightholder = shareNumber.shareholder();

        address term = _getSHA().getTerm(uint8(TermTitle.TAG_ALONG));

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

        _clearMsgSender();
    }

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external onlyDirectKeeper {
        uint32 rightholder = IAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        address term = _getSHA().getTerm(uint8(TermTitle.DRAG_ALONG));

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

        _clearMsgSender();
    }

    function _execAlongRight(
        uint32 rightholder,
        address term,
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) private currentDate(execDate) {
        require(
            !_bom.isProposed(ia) || _bom.votingDeadline(ia) >= execDate,
            "MISSED voting deadline"
        );

        uint32 seller = shareNumber.shareholder();

        uint32 drager = IAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        require(
            _bridgedMsgSender == rightholder,
            "_bridgedMsgSender NOT rightholder"
        );

        require(IAlongs(term).isTriggered(ia, sn), "TagAlong NOT triggered");

        require(IAlongs(term).isLinked(drager, seller), "NOT linked");

        require(
            IAlongs(term).priceCheck(ia, sn, shareNumber),
            "price NOT satisfied"
        );

        // test quota of alongDeal and update mock results
        _boa.addAlongDeal(
            ia,
            IAlongs(term).linkRule(_bos.groupNo(drager)),
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

    function acceptAlongDeal(
        address ia,
        uint32 drager,
        bytes32 sn
    ) external onlyDirectKeeper {
        require(
            _bom.votingDeadline(ia) >= now - 15 minutes,
            "MISSED voting deadline"
        );

        require(
            _bridgedMsgSender == sn.buyerOfDeal(),
            "_bridgedMsgSender NOT buyer"
        );

        _clearMsgSender();

        require(
            ISigPage(ia).sigDate(sn.buyerOfDeal()) > 0,
            "pls SIGN the along deal first"
        );

        _boa.acceptAlongDeal(ia, drager, sn);

        if (_boa.stateOfDoc(ia) == 1) _bom.resumeVoting(ia);
    }

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 execDate
    ) external onlyDirectKeeper currentDate(execDate) {
        require(
            !_bom.isProposed(ia) || _bom.votingDeadline(ia) >= execDate,
            "MISSED voting deadline"
        );

        require(
            _bom.isVoted(ia, _bridgedMsgSender),
            "first refusal reqeuster shall not cast vote"
        );

        address term = _getSHA().getTerm(uint8(TermTitle.FIRST_REFUSAL));
        require(
            IFirstRefusal(term).isRightholder(
                sn.typeOfDeal(),
                _bridgedMsgSender
            ),
            "NOT first refusal rightholder"
        );

        bool basedOnPar = _getSHA()
            .votingRules(sn.typeOfDeal())
            .basedOnParOfVR();

        IAgreement(ia).recordFRRequest(
            sn.sequenceOfDeal(),
            _bridgedMsgSender,
            basedOnPar,
            execDate
        );

        _clearMsgSender();

        _bom.suspendVoting(ia);
    }

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate
    ) external onlyDirectKeeper currentDate(acceptDate) {
        require(
            _bom.votingDeadline(ia) >= acceptDate,
            "MISSED voting deadline"
        );

        require(
            _bridgedMsgSender ==
                IAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder(),
            "not seller of Deal"
        );

        IAgreement(ia).acceptFR(
            sn.sequenceOfDeal(),
            _bridgedMsgSender,
            acceptDate
        );

        _clearMsgSender();
    }

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint256 closingDate
    ) external onlyDirectKeeper {
        require(_bom.isPassed(ia), "Motion NOT passed");

        require(_boa.isSubmitted(ia), "Agreement NOT in submitted state");

        if (sn.typeOfDeal() > 1) {
            require(
                _bridgedMsgSender ==
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
            require(
                _bridgedMsgSender == getDirectKeeper(),
                "NOT GeneralKeeper"
            );
            _checkSHA(_termsForCapitalIncrease, ia, sn);
        }

        _clearMsgSender();

        IAgreement(ia).clearDealCP(sn.sequenceOfDeal(), hashLock, closingDate);
    }

    function _checkSHA(
        TermTitle[] terms,
        address ia,
        bytes32 sn
    ) private {
        uint256 len = terms.length;
        for (uint256 i = 0; i < len; i++)
            if (_getSHA().hasTitle(uint8(terms[i])))
                require(
                    _getSHA().termIsExempted(uint8(terms[i]), ia, sn),
                    "SHA check failed"
                );
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        uint32 closingDate,
        string hashKey
    ) external onlyDirectKeeper currentDate(closingDate) {
        require(_boa.isSubmitted(ia), "Agreement NOT in submitted state");

        (
            ,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            ,
            ,

        ) = IAgreement(ia).getDeal(sn.sequenceOfDeal());

        //交易发起人为买方;
        require(
            sn.buyerOfDeal() == _bridgedMsgSender,
            "_bridgedMsgSender is NOT buyer"
        );

        _clearMsgSender();

        //验证hashKey, 执行Deal
        IAgreement(ia).closeDeal(sn.sequenceOfDeal(), hashKey);

        bytes32 shareNumber = IAgreement(ia).shareNumberOfDeal(
            sn.sequenceOfDeal()
        );

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
        address ia,
        bytes32 sn,
        string hashKey
    ) external onlyDirectKeeper {
        require(_boa.isRegistered(ia), "IA NOT registered");

        require(
            (sn.typeOfDeal() == 1) ||
                _bridgedMsgSender ==
                IAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder(),
            "NOT seller or bookeeper"
        );

        _clearMsgSender();

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
