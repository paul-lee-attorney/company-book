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
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";

import "./IBOAKeeper.sol";

contract BOAKeeper is
    IBOAKeeper,
    BOASetting,
    SHASetting,
    BOMSetting,
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

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(
            IAccessControl(body).getManager(0) == caller,
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

    function createIA(uint8 typOfIA, address caller) external onlyManager(1) {
        require(_bos.isMember(_rc.userNo(caller)), "caller not MEMBER");

        address ia = _boa.createDoc(typOfIA, _rc.userNo(caller));

        IAccessControl(ia).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IBookSetting(ia).setBOS(address(_bos));
        IBookSetting(ia).setBOSCal(address(_bosCal));

        // copyRoleTo(KEEPERS, ia);
    }

    function removeIA(address ia, uint40 caller)
        external
        onlyManager(1)
        onlyOwnerOf(ia, caller)
        notEstablished(ia)
    {
        _releaseCleanParOfIA(ia);
        _boa.removeDoc(ia);
    }

    function _releaseCleanParOfIA(address ia) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();
        uint256 len = snList.length;

        while (len > 0) {
            bytes32 sn = snList[len - 1];
            if (sn.ssnOfDeal() > 0) _releaseCleanParOfDeal(ia, sn);
            len--;
        }
    }

    function _releaseCleanParOfDeal(address ia, bytes32 sn) private {
        (, , uint64 par,  , ) = IInvestmentAgreement(ia).getDeal(
            sn.sequence()
        );

        if (IInvestmentAgreement(ia).releaseDealSubject(sn.sequence()))
            _bos.increaseCleanPar(sn.ssnOfDeal(), par);
    }

    // ======== Circulate IA ========

    function circulateIA(address ia, address callerAddr)
        external
        onlyManager(1)
        onlyOwnerOf(ia, _rc.userNo(callerAddr))
    {
        require(
            IAccessControl(ia).finalized(),
            "BOAKeeper.circualteIA: IA not finalized"
        );

        IAccessControl(ia).setManager(0, callerAddr, address(0));

        _boa.circulateIA(ia, _rc.userNo(callerAddr));
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyPartyOf(ia, caller) {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Circulated),
            "IA not in Circulated State"
        );

        _lockDealsOfParty(ia, caller);

        ISigPage(ia).signDoc(caller, sigHash);

        if (ISigPage(ia).established()) {
            // _boa.calculateMockResult(ia);
            _boa.pushToNextState(ia, caller);
        }
    }

    function _lockDealsOfParty(address ia, uint40 caller) private onlyKeeper {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();
        uint256 len = snList.length;
        // uint64 amount;
        while (len > 0) {
            bytes32 sn = snList[len - 1];
            len--;

            uint16 seq = sn.sequence();

            (, uint64 paid, , , ) = IInvestmentAgreement(ia).getDeal(seq);
            // amount = _getSHA().basedOnPar() ? parValue : paidPar;

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
                sn.typeOfDeal() == uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease)
            ) IInvestmentAgreement(ia).lockDealSubject(seq);
            // _boa.mockDealOfBuy(ia, seq, caller, amount);
        }
    }

    // ======== PayInCapital ========

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external onlyManager(1) {
        _bos.setPayInAmount(ssn, amount, hashLock);
    }

    function requestPaidInCapital(
        uint32 ssn,
        string memory hashKey,
        uint40 caller
    ) external onlyManager(1) {
        (bytes32 shareNumber, , , , ) = _bos.getShare(ssn);
        require(
            caller == shareNumber.shareholder(),
            "caller is not shareholder"
        );
        _bos.requestPaidInCapital(ssn, hashKey);
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint32 closingDate,
        uint40 caller
    ) external onlyManager(1) {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "wrong state of BOD"
        );

        if (sn.ssnOfDeal() > 0)
            require(
                caller ==
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(sn.sequence())
                        .shareholder(),
                "NOT seller"
            );
        else
            require(
                _bos.controllor() == caller,
                "caller is not controller"
            );

        bytes32 vr = _getSHA().votingRules(_boa.typeOfIA(ia));

        if (vr.ratioHeadOfVR() > 0 || vr.ratioAmountOfVR() > 0) {
            require(_bom.isPassed(uint256(uint160(ia))), "Motion NOT passed");

            if (sn.ssnOfDeal() > 0) _checkSHA(_termsForShareTransfer, ia, sn);
            else _checkSHA(_termsForCapitalIncrease, ia, sn);
        }

        IInvestmentAgreement(ia).clearDealCP(
            sn.sequence(),
            hashLock,
            closingDate
        );
    }

    function _checkSHA(
        ShareholdersAgreement.TermTitle[] memory terms,
        address ia,
        bytes32 sn
    ) private view {
        uint256 len = terms.length;

        while (len > 0) {
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
    ) external onlyManager(1) {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "InvestmentAgreement NOT in voted state"
        );

        //交易发起人为买方;
        require(sn.buyerOfDeal() == caller, "caller is NOT buyer");

        //验证hashKey, 执行Deal
        IInvestmentAgreement(ia).closeDeal(sn.sequence(), hashKey);

        transferTargetShare(ia, sn);

        _checkCompletionOfIA(ia, caller);
    }

    function _checkCompletionOfIA(address ia, uint40 caller) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();

        uint256 len = snList.length;
        while (len > 0) {
            (, , , uint8 state, ) = IInvestmentAgreement(ia).getDeal(
                snList[len - 1].sequence()
            );
            if (state < uint8(InvestmentAgreement.StateOfDeal.Closed)) break;
            len--;
        }

        if (len == 0) _boa.pushToNextState(ia, caller);
    }

    function transferTargetShare(address ia, bytes32 sn) public onlyManager(1) {
        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequence()
        );

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequence());

        uint32 unitPrice = IInvestmentAgreement(ia).unitPriceOfDeal(sn.sequence());

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > bytes32(0)) {
            _bos.increaseCleanPar(sn.ssnOfDeal(), paid);
            _bos.transferShare(
                shareNumber.ssn(),
                paid,
                par,
                sn.buyerOfDeal(),
                unitPrice
            );
        } else {
            _bos.issueShare(
                sn.buyerOfDeal(),
                sn.classOfDeal(),
                paid,
                par,
                uint32(block.timestamp), //paidInDeadline
                uint32(block.timestamp), //issueDate
                unitPrice //issuePrice
            );
        }
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        // uint32 sigDate,
        string memory hashKey
    ) external onlyManager(1) {
        require(_boa.isRegistered(ia), "IA NOT registered");
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "wrong State"
        );

        require(
            caller ==
                IInvestmentAgreement(ia)
                    .shareNumberOfDeal(sn.sequence())
                    .shareholder(),
            "NOT seller"
        );

        IInvestmentAgreement(ia).revokeDeal(
            sn.sequence(),
            // sigDate,
            hashKey
        );

        _releaseCleanParOfDeal(ia, sn);

        _checkCompletionOfIA(ia, caller);
    }
}
