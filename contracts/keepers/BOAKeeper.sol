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

import "../common/lib/SNFactory.sol";
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
    using SNFactory for bytes;
    using SNParser for bytes32;

    ShareholdersAgreement.TermTitle[] private _termsForCapitalIncrease = [
        ShareholdersAgreement.TermTitle.ANTI_DILUTION
    ];

    ShareholdersAgreement.TermTitle[] private _termsForShareTransfer = [
        ShareholdersAgreement.TermTitle.LOCK_UP,
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
        IAccessControl(ia).lockContents();

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

            uint16 seq = sn.seqOfDeal();

            (, uint64 paid, , , ) = IInvestmentAgreement(ia).getDeal(seq);

            if (sn.sellerOfDeal() == caller) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _bos.decreaseCleanPar(sn.ssnOfDeal(), paid);
                }
            } else if (
                sn.buyerOfDeal() == caller &&
                sn.typeOfDeal() ==
                uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease)
            ) IInvestmentAgreement(ia).lockDealSubject(seq);
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint48 closingDate,
        uint40 caller
    ) external onlyDK {
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "wrong state of BOD"
        );

        uint16 seq = sn.seqOfDeal();

        bool isST = (sn.ssnOfDeal() != 0);

        if (isST) require(caller == sn.sellerOfDeal(), "NOT seller");
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
            "BOAKeeper.closeDeal: InvestmentAgreement NOT in voted state"
        );

        //交易发起人为买方;
        require(
            sn.buyerOfDeal() == caller,
            "BOAKeeper.closeDeal: caller is NOT buyer"
        );

        uint16 seq = sn.seqOfDeal();

        //验证hashKey, 执行Deal
        if (IInvestmentAgreement(ia).closeDeal(seq, hashKey))
            _boa.pushToNextState(ia);

        uint32 ssn = sn.ssnOfDeal();

        if (ssn > 0) {
            _shareTransfer(ia, sn);
        } else issueNewShare(ia, sn);
    }

    function _shareTransfer(address ia, bytes32 sn) private {
        uint16 seq = sn.seqOfDeal();
        uint32 ssn = sn.ssnOfDeal();

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        uint32 unitPrice = sn.priceOfDeal();
        uint40 buyer = sn.buyerOfDeal();

        _bos.increaseCleanPar(ssn, paid);
        _bos.transferShare(ssn, paid, par, buyer, unitPrice);
    }

    function issueNewShare(address ia, bytes32 sn) public onlyDK {
        uint16 seq = sn.seqOfDeal();

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        bytes32 shareNumber = _createShareNumber(
            sn.classOfDeal(),
            sn.buyerOfDeal(),
            sn.priceOfDeal()
        );

        uint48 paidInDeadline;

        unchecked {
            paidInDeadline = uint48(block.timestamp) + 1800;
        }

        _bos.issueShare(shareNumber, paid, par, paidInDeadline);
    }

    function _createShareNumber(
        uint16 class,
        uint40 shareholder,
        uint32 unitPrice
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.seqToSN(0, class);
        _sn = _sn.acctToSN(12, shareholder);
        _sn = _sn.ssnToSN(17, unitPrice);

        return _sn.bytesToBytes32();
    }

    function transferTargetShare(
        address ia,
        bytes32 sn,
        uint40 caller
    ) public onlyDK {
        require(
            caller == sn.sellerOfDeal(),
            "BOAKeeper.transferTargetShare: caller not seller of Deal"
        );

        _shareTransfer(ia, sn);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        string memory hashKey
    ) external onlyDK {
        require(
            _boa.isRegistered(ia),
            "BOAKeeper.revokeDeal: IA NOT registered"
        );
        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Voted),
            "BOAKeeper.revokeDeal: wrong State"
        );

        uint16 seq = sn.seqOfDeal();

        require(
            caller == sn.sellerOfDeal(),
            "BOAKeeper.revokeDeal: NOT seller"
        );

        if (IInvestmentAgreement(ia).revokeDeal(seq, hashKey))
            _boa.pushToNextState(ia);

        (, , uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        if (IInvestmentAgreement(ia).releaseDealSubject(seq))
            _bos.increaseCleanPar(sn.ssnOfDeal(), par);
    }
}
