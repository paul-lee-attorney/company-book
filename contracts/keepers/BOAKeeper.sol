// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boa/InvestmentAgreement.sol";
import "../books/boa/IInvestmentAgreement.sol";
import "../books/boh/ShareholdersAgreement.sol";

import "../common/access/IAccessControl.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/ROMSetting.sol";

import "../common/lib/SNParser.sol";

import "./IBOAKeeper.sol";

contract BOAKeeper is
    IBOAKeeper,
    BOASetting,
    BOHSetting,
    BOMSetting,
    BOSSetting,
    ROMSetting
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

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(
            caller != 0 && IAccessControl(body).getManager(0) == caller,
            "NOT Owner of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address ia, uint40 caller) {
        require(ISigPage(ia).isParty(caller), "NOT Owner of Doc");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function setTempOfIA(address temp, uint8 typeOfDoc) external onlyDK {
        _boa.setTemplate(temp, typeOfDoc);
    }

    function createIA(uint8 typOfIA, uint40 caller) external onlyDK {
        require(_rom.isMember(caller), "caller not MEMBER");

        address ia = _boa.createDoc(typOfIA, caller);

        IAccessControl(ia).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IBookSetting(ia).setBOS(address(_bos));
        IBookSetting(ia).setROM(address(_rom));
    }

    function removeIA(address ia, uint40 caller)
        external
        onlyDK
        onlyOwnerOf(ia, caller)
    {
        _boa.removeDoc(ia);
    }

    // ======== Circulate IA ========

    function circulateIA(address ia, uint40 caller)
        external
        onlyDK
        onlyOwnerOf(ia, caller)
    {
        require(
            IAccessControl(ia).finalized(),
            "BOAKeeper.circualteIA: IA not finalized"
        );

        IAccessControl(ia).setManager(0, 0);

        _boa.circulateIA(ia);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyPartyOf(ia, caller) {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Circulated),
            "IA not in Circulated State"
        );

        _lockDealsOfParty(ia, caller);

        ISigPage(ia).signDoc(caller, sigHash);

        if (ISigPage(ia).established()) {
            _boa.pushToNextState(ia);
        }
    }

    function _lockDealsOfParty(address ia, uint40 caller) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();
        uint256 len = snList.length;
        while (len != 0) {
            bytes32 sn = snList[len - 1];
            len--;

            uint16 seq = sn.sequence();

            (, uint64 paid, , , ) = IInvestmentAgreement(ia).getDeal(seq);

            bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
                seq
            );

            if (shareNumber.shareholder() == caller) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _bos.decreaseCleanPar(sn.ssnOfDeal(), paid);
                    // _boa.mockDealOfSell(ia, caller, amount);
                }
            } else if (
                sn.buyerOfDeal() == caller &&
                sn.typeOfDeal() ==
                uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease)
            ) IInvestmentAgreement(ia).lockDealSubject(seq);
            // _boa.mockDealOfBuy(ia, seq, caller, amount);
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint32 closingDate,
        uint40 caller
    ) external onlyDK {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "wrong state of BOD"
        );

        uint16 seq = sn.sequence();

        bool isST = sn.ssnOfDeal() != 0;

        if (isST)
            require(
                caller ==
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(seq)
                        .shareholder(),
                "NOT seller"
            );
        else require(_rom.controllor() == caller, "caller is not controller");

        bytes32 vr = _getSHA().votingRules(IInvestmentAgreement(ia).typeOfIA());

        if (vr.ratioAmountOfVR() != 0 || vr.ratioHeadOfVR() != 0) {
            require(_bom.isPassed(uint256(uint160(ia))), "Motion NOT passed");

            if (isST) _checkSHA(_termsForShareTransfer, ia, sn);
            else _checkSHA(_termsForCapitalIncrease, ia, sn);
        }

        IInvestmentAgreement(ia).clearDealCP(seq, hashLock, closingDate);
    }

    function _checkSHA(
        ShareholdersAgreement.TermTitle[] memory terms,
        address ia,
        bytes32 sn
    ) private view {
        uint256 len = terms.length;

        while (len != 0) {
            if (_getSHA().hasTitle(uint8(terms[len - 1])))
                require(
                    _getSHA().termIsExempted(uint8(terms[len - 1]), ia, sn),
                    "SHA check failed"
                );
            len--;
        }
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey,
        uint40 caller
    ) external onlyDK {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "InvestmentAgreement NOT in voted state"
        );

        //交易发起人为买方;
        require(sn.buyerOfDeal() == caller, "caller is NOT buyer");

        uint16 seq = sn.sequence();

        //验证hashKey, 执行Deal
        IInvestmentAgreement(ia).closeDeal(seq, hashKey);

        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(seq);

        if (shareNumber > bytes32(0)) _shareTransfer(ia, sn, shareNumber);
        else issueNewShare(ia, sn);

        _checkCompletionOfIA(ia);
    }

    function _checkCompletionOfIA(address ia) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();

        uint256 len = snList.length;
        while (len != 0) {
            (, , , uint8 state, ) = IInvestmentAgreement(ia).getDeal(
                snList[len - 1].sequence()
            );
            if (state < uint8(InvestmentAgreement.StateOfDeal.Closed)) break;
            len--;
        }

        if (len == 0) _boa.pushToNextState(ia);
    }

    function _shareTransfer(
        address ia,
        bytes32 sn,
        bytes32 shareNumber
    ) private {
        uint16 seq = sn.sequence();

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        uint32 unitPrice = IInvestmentAgreement(ia).unitPriceOfDeal(seq);

        _bos.increaseCleanPar(sn.ssnOfDeal(), paid);
        _bos.transferShare(
            shareNumber.ssn(),
            paid,
            par,
            sn.buyerOfDeal(),
            unitPrice
        );
    }

    function issueNewShare(address ia, bytes32 sn) public onlyDK {
        uint16 seq = sn.sequence();

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        uint32 unitPrice = IInvestmentAgreement(ia).unitPriceOfDeal(seq);

        bytes32 shareNumber = _bos.createShareNumber(
            sn.classOfDeal(),
            _bos.counterOfShares() + 1,
            uint32(block.timestamp),
            unitPrice,
            sn.buyerOfDeal(),
            0
        );

        _bos.issueShare(
            shareNumber,
            paid,
            par,
            uint32(block.timestamp) //paidInDeadline
        );
    }

    function transferTargetShare(
        address ia,
        bytes32 sn,
        uint40 caller
    ) public onlyDK {
        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequence()
        );

        require(
            caller == shareNumber.shareholder(),
            "BOAKeeper.transferTargetShare: caller not shareholder"
        );

        _shareTransfer(ia, sn, shareNumber);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        string memory hashKey
    ) external onlyDK {
        require(_boa.isRegistered(ia), "IA NOT registered");
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "wrong State"
        );

        uint16 seq = sn.sequence();

        require(
            caller ==
                IInvestmentAgreement(ia).shareNumberOfDeal(seq).shareholder(),
            "NOT seller"
        );

        IInvestmentAgreement(ia).revokeDeal(seq, hashKey);

        (, , uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        if (IInvestmentAgreement(ia).releaseDealSubject(seq))
            _bos.increaseCleanPar(sn.ssnOfDeal(), par);

        // _releaseCleanParOfDeal(ia, sn);

        _checkCompletionOfIA(ia);
    }

    // function _releaseCleanParOfDeal(address ia, bytes32 sn) private {
    //     (, , uint64 par, , ) = IInvestmentAgreement(ia).getDeal(sn.sequence());

    //     if (IInvestmentAgreement(ia).releaseDealSubject(sn.sequence()))
    //         _bos.increaseCleanPar(sn.ssnOfDeal(), par);
    // }
}
