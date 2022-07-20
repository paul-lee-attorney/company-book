/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/terms/IAntiDilution.sol";
import "../books/boh/ShareholdersAgreement.sol";
import "../books/boh/terms/ITerm.sol";

import "../books/boa/IInvestmentAgreement.sol";
import "../books/boa/InvestmentAgreement.sol";

import "../books/boh/terms/IAlongs.sol";
import "../books/boh/terms/IFirstRefusal.sol";

import "../common/access/IRoles.sol";
import "../common/access/IAccessControl.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";

import "./IBOAKeeper.sol";

contract BOAKeeper is
    IBOAKeeper,
    BOASetting,
    SHASetting,
    BOMSetting,
    BOSSetting
{
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

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(IAccessControl(body).getOwner() == caller, "NOT Owner of Doc");
        _;
    }

    modifier onlyPartyOf(address ia, uint40 caller) {
        require(ISigPage(ia).isParty(caller), "NOT Owner of Doc");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint8 typOfIA, uint40 caller) external onlyDirectKeeper {
        require(_bos.isMember(caller), "caller not MEMBER");

        address ia = _boa.createDoc(typOfIA, caller);

        IAccessControl(ia).init(caller, _rc.userNo(this), address(_rc));

        IBookSetting(ia).setBOS(address(_bos));
        IBookSetting(ia).setBOSCal(address(_bosCal));

        _copyRoleTo(ia, KEEPERS);
    }

    function removeIA(address ia, uint40 caller)
        external
        onlyDirectKeeper
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
            if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
                _releaseCleanParOfDeal(ia, sn);
            len--;
        }
    }

    function _releaseCleanParOfDeal(address ia, bytes32 sn) private {
        (, uint64 parValue, , , ) = IInvestmentAgreement(ia).getDeal(
            sn.sequence()
        );

        if (IInvestmentAgreement(ia).releaseDealSubject(sn.sequence()))
            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
    }

    // ======== Circulate IA ========

    function circulateIA(address ia, uint40 submitter)
        external
        onlyDirectKeeper
        onlyOwnerOf(ia, submitter)
    {
        require(IDraftControl(ia).finalized(), "let GC finalize IA first");

        IAccessControl(ia).abandonOwnership();

        _boa.circulateIA(ia, submitter);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Circulated),
            "IA not in Circulated State"
        );

        _mockDealsOfParty(ia, caller);

        ISigPage(ia).signDoc(caller, sigHash);

        if (ISigPage(ia).established()) {
            _boa.calculateMockResult(ia);
            _boa.pushToNextState(ia, caller);
        }
    }

    function _mockDealsOfParty(address ia, uint40 caller) private onlyKeeper {
        uint16[] memory seqList = IInvestmentAgreement(ia).dealsConcerned(
            caller
        );
        uint256 len = seqList.length;
        uint64 amount;

        while (len > 0) {
            uint16 seq = seqList[len - 1];

            (
                bytes32 sn,
                uint64 parValue,
                uint64 paidPar,
                ,

            ) = IInvestmentAgreement(ia).getDeal(seq);

            amount = _getSHA().basedOnPar() ? parValue : paidPar;

            if (!IInvestmentAgreement(ia).isBuyerOfDeal(caller, seq)) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _bos.decreaseCleanPar(
                        sn.shortShareNumberOfDeal(),
                        parValue
                    );
                    _boa.mockDealOfSell(ia, caller, amount);
                }
            } else {
                if (
                    sn.typeOfDeal() ==
                    uint8(EnumsRepo.TypeOfDeal.CapitalIncrease)
                ) IInvestmentAgreement(ia).lockDealSubject(seq);
                _boa.mockDealOfBuy(ia, seq, caller, amount);
            }

            len--;
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint32 closingDate,
        uint40 caller
    ) external onlyDirectKeeper {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Voted),
            "wrong state of BOD"
        );

        if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
            require(
                caller ==
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(sn.sequence())
                        .shareholder(),
                "NOT seller"
            );
        else
            require(
                _bos.controller() == _bos.groupNo(caller),
                "caller is not controller"
            );

        bytes32 vr = _getSHA().votingRules(_boa.typeOfIA(ia));

        if (vr.ratioHeadOfVR() > 0 || vr.ratioAmountOfVR() > 0) {
            require(_bom.isPassed(uint256(ia)), "Motion NOT passed");

            if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
                _checkSHA(_termsForShareTransfer, ia, sn);
            else _checkSHA(_termsForCapitalIncrease, ia, sn);
        }

        IInvestmentAgreement(ia).clearDealCP(
            sn.sequence(),
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
        string hashKey,
        uint40 caller
    ) external onlyDirectKeeper {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Voted),
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
            if (state < uint8(EnumsRepo.StateOfDeal.Closed)) break;
            len--;
        }

        if (len == 0) _boa.pushToNextState(ia, caller);
    }

    function transferTargetShare(address ia, bytes32 sn)
        public
        onlyDirectKeeper
    {
        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequence()
        );

        (, uint64 parValue, uint64 paidPar, , ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequence());

        uint32 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > bytes32(0)) {
            _bos.increaseCleanPar(sn.shortShareNumberOfDeal(), parValue);
            _bos.transferShare(
                shareNumber.short(),
                parValue,
                paidPar,
                sn.buyerOfDeal(),
                unitPrice
            );
        } else {
            _bos.issueShare(
                sn.buyerOfDeal(),
                sn.classOfDeal(),
                parValue,
                paidPar,
                uint32(block.timestamp), //paidInDeadline
                uint32(block.timestamp), //issueDate
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
        uint40 caller,
        // uint32 sigDate,
        string hashKey
    ) external onlyDirectKeeper {
        require(_boa.isRegistered(ia), "IA NOT registered");
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Voted),
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
