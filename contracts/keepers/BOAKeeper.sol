/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/access/interfaces/IRoles.sol";
import "../common/access/interfaces/IAccessControl.sol";

import "../common/components/interfaces/ISigPage.sol";
// import "../common/components/EnumsRepo.sol";

import "../books/boh/terms/interfaces/IAntiDilution.sol";
import "../books/boh/ShareholdersAgreement.sol";
import "../books/boa/interfaces/IInvestmentAgreement.sol";
import "../books/boa/InvestmentAgreement.sol";

import "../books/boh/terms/interfaces/IAlongs.sol";
import "../books/boh/terms/interfaces/IFirstRefusal.sol";

import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/ruting/BOOSetting.sol";

import "../common/lib/SNParser.sol";

contract BOAKeeper is
    BOASetting,
    SHASetting,
    BOMSetting,
    BOOSetting,
    BOSSetting
{
    using SNParser for bytes32;

    ShareholdersAgreement.TermTitle[] private _termsForCapitalIncrease = [
        ShareholdersAgreement.TermTitle.ANTI_DILUTION,
        ShareholdersAgreement.TermTitle.FIRST_REFUSAL
    ];

    ShareholdersAgreement.TermTitle[] private _termsForShareTransfer = [
        ShareholdersAgreement.TermTitle.LOCK_UP,
        ShareholdersAgreement.TermTitle.FIRST_REFUSAL,
        ShareholdersAgreement.TermTitle.TAG_ALONG,
        ShareholdersAgreement.TermTitle.DRAG_ALONG
    ];

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinReviewPeriod(address body, uint32 sigDate) {
        require(_boa.reviewDeadlineOf(body) >= sigDate, "missed review period");
        _;
    }

    modifier beEstablished(address body) {
        require(ISigPage(body).established(), "Doc NOT Established");
        _;
    }

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint32 caller) {
        require(IAccessControl(body).getOwner() == caller, "NOT Owner of Doc");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint8 docType, uint32 caller) external onlyDirectKeeper {
        require(_bos.isMember(caller), "caller not MEMBER");

        address body = _boa.createDoc(docType);

        IAccessControl(body).init(caller, _rc.userNo(this), address(_rc));

        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setBOSCal(address(_bosCal));

        _copyRoleTo(body, KEEPERS);
    }

    function removeIA(address body, uint32 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(body, caller)
        notEstablished(body)
    {
        _boa.removeDoc(body);
        IInvestmentAgreement(body).kill();
    }

    function submitIA(
        address body,
        uint32 caller,
        uint32 submitDate,
        bytes32 docHash
    ) external onlyDirectKeeper onlyOwnerOf(body, caller) beEstablished(body) {
        _boa.submitIA(body, caller, submitDate, docHash);
        _decreaseCleanPar(body, submitDate);
        IAccessControl(body).abandonOwnership();
    }

    function _decreaseCleanPar(address body, uint32 submitDate) private {
        bytes32[] memory snList = IInvestmentAgreement(body).dealsList();
        uint256 len = snList.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 sn = snList[i];
            if (
                sn.typeOfDeal() <=
                uint8(InvestmentAgreement.TypeOfDeal.PreEmptive)
            ) continue;
            if (
                IInvestmentAgreement(body).lockDealSubject(
                    sn.sequenceOfDeal(),
                    submitDate
                )
            ) {
                (, uint256 parValue, , , ) = IInvestmentAgreement(body).getDeal(
                    sn.sequenceOfDeal()
                );
                _bos.decreaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
            }
        }
    }

    // ======== TagAlong ========

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        withinReviewPeriod(ia, sigDate)
    {
        _addAlongDeal(
            false,
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            caller,
            sigDate
        );

        bytes32 taSN = _createTagAlongDeal(ia, shareNumber, sn);

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

        IInvestmentAgreement(ia).updateDeal(
            taSN.sequenceOfDeal(),
            unitPrice,
            parValue,
            paidPar,
            closingDate
        );
    }

    function _createTagAlongDeal(
        address ia,
        bytes32 shareNumber,
        bytes32 sn
    ) private returns (bytes32 taSN) {
        taSN = IInvestmentAgreement(ia).createDeal(
            uint8(InvestmentAgreement.TypeOfDeal.TagAlong),
            shareNumber,
            shareNumber.class(),
            sn.buyerOfDeal(),
            sn.groupOfBuyer(),
            sn.sequence()
        );
    }

    function acceptTagAlongDeal(
        address ia,
        uint32 drager,
        bytes32 sn,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        withinReviewPeriod(ia, sigDate)
    {
        // require(_bom.votingDeadline(ia) >= sigDate, "MISSED voting deadline");

        require(caller == sn.buyerOfDeal(), "caller NOT buyer");

        IInvestmentAgreement(ia).acceptTagAlongDeal(
            sn.shortShareNumberOfDeal(),
            caller,
            sigDate,
            sigHash
        );

        // require(
        //     ISigPage(ia).sigDate(sn.buyerOfDeal()) > 0,
        //     "pls SIGN the along deal first"
        // );

        _boa.acceptTagAlongDeal(ia, drager, sn);

        // if (_boa.stateOfDoc(ia) == 1) _bom.resumeVoting(ia);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        withinReviewPeriod(ia, sigDate)
    {
        require(
            caller == shareNumber.shareholder(),
            "caller is not shareholder"
        );

        address ad = _getSHA().getTerm(
            uint8(ShareholdersAgreement.TermTitle.ANTI_DILUTION)
        );

        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

        uint256 giftPar = IAntiDilution(ad).giftPar(ia, sn, shareNumber);
        uint32[] memory obligors = IAntiDilution(ad).obligors(
            shareNumber.class()
        );

        _createGiftDeals(ia, giftPar, closingDate, obligors, caller, sigDate);

        ISigPage(ia).addPartyToDoc(shareNumber.shareholder());
        ISigPage(ia).addSigOfParty(shareNumber.shareholder(), sigDate, sigHash);

        // _createOption(ia, sn, shareNumber, parValue, paidPar, sigDate);
    }

    function _createGiftDeals(
        address ia,
        uint256 giftPar,
        uint32 closingDate,
        uint32[] obligors,
        uint32 caller,
        uint32 sigDate
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _bos.sharesInHand(obligors[i]);
            for (uint256 j = 0; j < sharesInHand.length; j++) {
                uint256 targetCleanPar = _bos.cleanPar(sharesInHand[j].short());

                if (targetCleanPar > 0) {
                    bytes32 snOfGiftDeal = IInvestmentAgreement(ia).createDeal(
                        uint8(InvestmentAgreement.TypeOfDeal.FreeGift),
                        sharesInHand[j],
                        sharesInHand[j].class(),
                        caller,
                        _bos.groupNo(caller),
                        0
                    );

                    if (targetCleanPar < giftPar) {
                        _lockDealSubject(
                            ia,
                            snOfGiftDeal,
                            sharesInHand[j].shortShareNumberOfDeal(),
                            targetCleanPar,
                            closingDate,
                            sigDate
                        );
                        giftPar -= targetCleanPar;
                        continue;
                    } else {
                        _lockDealSubject(
                            ia,
                            snOfGiftDeal,
                            sharesInHand[j].shortShareNumberOfDeal(),
                            giftPar,
                            closingDate,
                            sigDate
                        );
                        giftPar = 0;
                        break;
                    }
                }
            }
            if (giftPar == 0) break;
        }

        require(giftPar == 0, "obligors have not enough parValue");
    }

    function _lockDealSubject(
        address ia,
        bytes32 snOfGiftDeal,
        bytes6 ssn,
        uint256 lockAmount,
        uint32 closingDate,
        uint32 sigDate
    ) private {
        IInvestmentAgreement(ia).updateDeal(
            snOfGiftDeal.sequenceOfDeal(),
            0,
            lockAmount,
            lockAmount,
            closingDate
        );
        IInvestmentAgreement(ia).lockDealSubject(
            snOfGiftDeal.sequenceOfDeal(),
            sigDate
        );
        _bos.decreaseCleanPar(ssn, lockAmount);
    }

    // ======== DragAlong ========

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        withinReviewPeriod(ia, sigDate)
    {
        _addAlongDeal(
            true,
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            caller,
            sigDate
        );

        ISigPage(ia).addPartyToDoc(shareNumber.shareholder());
        ISigPage(ia).addSigOfParty(shareNumber.shareholder(), sigDate, sigHash);

        _createOption(ia, sn, shareNumber, parValue, paidPar, sigDate);
    }

    function _addAlongDeal(
        bool dragAlong,
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 sigDate
    ) private {
        require(_boa.isSubmitted(ia), "ia not submitted");
        require(!_boa.passedReview(ia), "ia passed review");

        uint32 drager = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        address term = dragAlong
            ? _getSHA().getTerm(
                uint8(ShareholdersAgreement.TermTitle.DRAG_ALONG)
            )
            : _getSHA().getTerm(
                uint8(ShareholdersAgreement.TermTitle.TAG_ALONG)
            );

        require(
            ITerm(term).isTriggered(ia, sn.sequenceOfDeal()),
            "not triggered"
        );

        if (dragAlong)
            require(caller == drager, "caller is not drager of DragAlong");
        else
            require(
                caller == shareNumber.shareholder(),
                "caller is not shareholder of TagAlong"
            );

        require(
            IAlongs(term).isLinked(drager, shareNumber.shareholder()),
            "drager and target shareholder NOT linked"
        );

        if (dragAlong)
            require(
                IAlongs(term).priceCheck(ia, sn, shareNumber, caller),
                "price NOT satisfied"
            );

        // test quota of alongDeal and update mock results
        _boa.addAlongDeal(
            ia,
            IAlongs(term).linkRule(_bos.groupNo(drager)),
            shareNumber,
            parValue,
            paidPar,
            caller,
            sigDate
        );
    }

    function _createOption(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 sigDate
    ) private {
        uint8 closingDays = uint8(
            (IInvestmentAgreement(ia).closingDate(sn.sequenceOfDeal()) -
                sigDate) / 86400
        );

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        _boo.createOption(
            0,
            sn.buyerOfDeal(),
            shareNumber.shareholder(),
            sigDate,
            closingDays,
            closingDays,
            unitPrice,
            parValue,
            paidPar
        );
    }

    function acceptDragAlong(
        // bytes32 sn,
        bytes32 snOfOpt,
        bytes32 shareNumber,
        uint32 caller,
        uint32 sigDate
    ) external onlyDirectKeeper currentDate(sigDate) {
        // require(caller == sn.buyerOfDeal(), "caller NOT buyer");

        (, uint32 rightholder, , uint256 parValue, uint256 paidPar, , ) = _boo
            .getOption(snOfOpt.shortOfOpt());

        require(caller == rightholder, "caller not rightholder of option");

        _boo.execOption(snOfOpt.shortOfOpt(), sigDate);

        _boo.addFuture(snOfOpt.shortOfOpt(), shareNumber, parValue, paidPar);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external onlyDirectKeeper currentDate(sigDate) {
        address term = _getSHA().getTerm(
            uint8(ShareholdersAgreement.TermTitle.FIRST_REFUSAL)
        );
        require(
            IFirstRefusal(term).isRightholder(sn.typeOfDeal(), caller),
            "NOT first refusal rightholder"
        );

        _boa.rejectDoc(ia, sigDate, caller);

        bool basedOnPar = _getSHA()
            .votingRules(sn.typeOfDeal())
            .basedOnParOfVR();

        IInvestmentAgreement(ia).recordFRRequest(
            sn.sequenceOfDeal(),
            basedOnPar,
            caller,
            sigDate,
            sigHash
        );
    }

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 acceptDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(acceptDate)
        withinReviewPeriod(ia, acceptDate)
    {
        require(
            _bom.votingDeadline(ia) >= acceptDate,
            "MISSED voting deadline"
        );

        require(
            caller ==
                IInvestmentAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder(),
            "not seller of Deal"
        );

        IInvestmentAgreement(ia).acceptFR(
            sn.sequenceOfDeal(),
            caller,
            acceptDate,
            sigHash
        );
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint256 closingDate,
        uint32 caller,
        uint32 sigDate
    ) external onlyDirectKeeper currentDate(sigDate) {
        require(_bom.isPassed(ia), "Motion NOT passed");

        require(
            _boa.isSubmitted(ia),
            "InvestmentAgreement NOT in submitted state"
        );

        if (sn.typeOfDeal() > 1) {
            require(
                caller ==
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(sn.sequenceOfDeal())
                        .shareholder(),
                "NOT seller"
            );

            _checkSHA(_termsForShareTransfer, ia, sn);
        } else {
            _checkSHA(_termsForCapitalIncrease, ia, sn);
        }

        IInvestmentAgreement(ia).clearDealCP(
            sn.sequenceOfDeal(),
            sigDate,
            hashLock,
            closingDate
        );
    }

    function _checkSHA(
        ShareholdersAgreement.TermTitle[] terms,
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
        string hashKey,
        uint32 caller
    ) external onlyDirectKeeper currentDate(closingDate) {
        require(
            _boa.isSubmitted(ia),
            "InvestmentAgreement NOT in submitted state"
        );

        (, uint256 parValue, uint256 paidPar, , ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequenceOfDeal());

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        //交易发起人为买方;
        require(sn.buyerOfDeal() == caller, "caller is NOT buyer");

        //验证hashKey, 执行Deal
        IInvestmentAgreement(ia).closeDeal(
            sn.sequenceOfDeal(),
            closingDate,
            hashKey
        );

        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
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
        uint32 caller,
        uint32 sigDate,
        string hashKey
    ) external onlyDirectKeeper currentDate(sigDate) {
        require(_boa.isRegistered(ia), "IA NOT registered");

        require(
            (sn.typeOfDeal() == 1) ||
                caller ==
                IInvestmentAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder(),
            "NOT seller or bookeeper"
        );

        IInvestmentAgreement(ia).revokeDeal(
            sn.sequenceOfDeal(),
            sigDate,
            hashKey
        );

        if (sn.typeOfDeal() > 1) {
            (, uint256 parValue, , , ) = IInvestmentAgreement(ia).getDeal(
                sn.sequenceOfDeal()
            );

            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
            _bos.updateShareState(sn.shortShareNumberOfDeal(), 0);
        }
    }
}
