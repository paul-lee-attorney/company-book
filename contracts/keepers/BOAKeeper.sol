/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/terms/interfaces/IAntiDilution.sol";
import "../books/boh/ShareholdersAgreement.sol";
import "../books/boh/interfaces/ITerm.sol";

import "../books/boa/interfaces/IInvestmentAgreement.sol";
import "../books/boa/InvestmentAgreement.sol";

import "../books/boh/terms/interfaces/IAlongs.sol";
import "../books/boh/terms/interfaces/IFirstRefusal.sol";

import "../common/access/interfaces/IRoles.sol";
import "../common/access/interfaces/IAccessControl.sol";

import "../common/components/interfaces/ISigPage.sol";

import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";

contract BOAKeeper is BOASetting, SHASetting, BOMSetting, BOSSetting {
    using SNParser for bytes32;

    EnumsRepo.TermTitle[] private _termsForCapitalIncrease = [
        EnumsRepo.TermTitle.ANTI_DILUTION,
        EnumsRepo.TermTitle.FIRST_REFUSAL
    ];

    EnumsRepo.TermTitle[] private _termsForShareTransfer = [
        EnumsRepo.TermTitle.LOCK_UP,
        EnumsRepo.TermTitle.FIRST_REFUSAL,
        EnumsRepo.TermTitle.TAG_ALONG,
        EnumsRepo.TermTitle.DRAG_ALONG
    ];

    // ##################
    // ##   Modifier   ##
    // ##################

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

        address ia = _boa.createDoc(docType);

        IAccessControl(ia).init(caller, _rc.userNo(this), address(_rc));

        IBookSetting(ia).setBOS(address(_bos));
        IBookSetting(ia).setBOSCal(address(_bosCal));

        _copyRoleTo(ia, KEEPERS);
    }

    function removeIA(
        address ia,
        uint32 caller,
        uint32 sigDate
    ) external onlyDirectKeeper onlyOwnerOf(ia, caller) notEstablished(ia) {
        _releaseCleanParOfIA(ia, sigDate);
        _boa.removeDoc(ia);
        IInvestmentAgreement(ia).kill();
    }

    function _releaseCleanParOfIA(address ia, uint32 releaseDate) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();
        uint256 len = snList.length;

        while (len > 0) {
            bytes32 sn = snList[len - 1];
            if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
                _releaseCleanParOfDeal(ia, sn, releaseDate);
            len--;
        }
    }

    function _releaseCleanParOfDeal(
        address ia,
        bytes32 sn,
        uint32 releaseDate
    ) private {
        (, uint256 parValue, , uint8 state, ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequenceOfDeal());

        if (state >= uint8(EnumsRepo.StateOfDeal.Locked)) {
            IInvestmentAgreement(ia).releaseDealSubject(
                sn.sequenceOfDeal(),
                releaseDate
            );
            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
        }
    }

    function submitIA(
        address body,
        uint32 caller,
        uint32 submitDate,
        bytes32 docHash
    ) external onlyDirectKeeper onlyOwnerOf(body, caller) beEstablished(body) {
        _boa.submitIA(body, caller, submitDate, docHash);
        _lockCleanParOfIA(body, submitDate);
        IAccessControl(body).abandonOwnership();
    }

    function _lockCleanParOfIA(address ia, uint32 lockDate) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();
        uint256 len = snList.length;

        while (len > 0) {
            bytes32 sn = snList[len - 1];
            if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
                _lockCleanParOfDeal(ia, sn, lockDate);
            len--;
        }
    }

    function _lockCleanParOfDeal(
        address ia,
        bytes32 sn,
        uint32 lockDate
    ) private {
        if (
            IInvestmentAgreement(ia).lockDealSubject(
                sn.sequenceOfDeal(),
                lockDate
            )
        ) {
            (, uint256 parValue, , , ) = IInvestmentAgreement(ia).getDeal(
                sn.sequenceOfDeal()
            );
            _bos.decreaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
        }
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
        EnumsRepo.TermTitle[] terms,
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
