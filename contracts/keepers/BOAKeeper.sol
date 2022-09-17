/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/IInvestmentAgreement.sol";

import "../common/access/IAccessControl.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOCSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";

import "./IBOAKeeper.sol";

contract BOAKeeper is
    IBOAKeeper,
    BOASetting,
    BOCSetting,
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
            this,
            _rc,
            uint8(EnumsRepo.RoleOfUser.InvestmentAgreement),
            _rc.entityNo(this)
        );

        IBookSetting(ia).setBOS(_bos);
        IBookSetting(ia).setBOSCal(_bosCal);

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
        (, uint64 parValue, , , ) = IInvestmentAgreement(ia).getDeal(
            sn.sequence()
        );

        if (IInvestmentAgreement(ia).releaseDealSubject(sn.sequence()))
            _bos.increaseCleanPar(sn.ssnOfDeal(), parValue);
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
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Circulated),
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

            (, , uint64 paidPar, , ) = IInvestmentAgreement(ia).getDeal(seq);
            // amount = _getSHA().basedOnPar() ? parValue : paidPar;

            bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
                seq
            );

            if (shareNumber.shareholder() == caller) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _bos.decreaseCleanPar(sn.ssnOfDeal(), paidPar);
                    // _boa.mockDealOfSell(ia, caller, amount);
                }
            } else if (
                sn.buyerOfDeal() == caller &&
                sn.typeOfDeal() == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease)
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
        string hashKey,
        uint40 caller
    ) external onlyManager(1) {
        (bytes32 shareNumber, , , , , ) = _bos.getShare(ssn);
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
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Voted),
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
                _boc.controller() == _boc.groupNo(caller),
                "caller is not controller"
            );

        bytes32 vr = _getSHA().votingRules(_boa.typeOfIA(ia));

        if (vr.ratioHeadOfVR() > 0 || vr.ratioAmountOfVR() > 0) {
            require(_bom.isPassed(uint256(ia)), "Motion NOT passed");

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
        EnumsRepo.TermTitle[] terms,
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
        string hashKey,
        uint40 caller
    ) external onlyManager(1) {
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

    function transferTargetShare(address ia, bytes32 sn) public onlyManager(1) {
        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequence()
        );

        (, uint64 parValue, uint64 paidPar, , ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequence());

        uint32 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > bytes32(0)) {
            _bos.increaseCleanPar(sn.ssnOfDeal(), parValue);
            _bos.transferShare(
                shareNumber.ssn(),
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

        // if (sn.groupOfBuyer() > 0)
        //     _boc.addMemberToGroup(sn.buyerOfDeal(), sn.groupOfBuyer());

        _boc.updateController(_getSHA().basedOnPar());
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        // uint32 sigDate,
        string hashKey
    ) external onlyManager(1) {
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
