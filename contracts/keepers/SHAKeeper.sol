// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/terms/IAntiDilution.sol";
import "../books/boh/terms/ITerm.sol";
import "../books/boh/terms/IAlongs.sol";

import "../books/boh/ShareholdersAgreement.sol";

import "../books/boa/InvestmentAgreement.sol";
import "../books/boa/IInvestmentAgreement.sol";
import "../books/boa/IFirstRefusalDeals.sol";
import "../books/boa/IMockResults.sol";

import "../common/components/DocumentsRepo.sol";
import "../common/components/ISigPage.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROMSetting.sol";
import "../common/ruting/BOHSetting.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/SNFactory.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is
    ISHAKeeper,
    BOASetting,
    BOSSetting,
    BOHSetting,
    ROMSetting
{
    using SNParser for bytes32;
    using SNFactory for bytes;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinReviewPeriod(address ia) {
        require(
            _boa.reviewDeadlineBNOf(ia) >= block.number,
            "missed review period"
        );
        _;
    }

    modifier afterReviewPeriod(address ia) {
        require(
            IDocumentsRepo(address(_boa)).reviewDeadlineBNOf(ia) < block.number,
            "still within review period"
        );
        _;
    }

    modifier onlyEstablished(address ia) {
        require(
            IDocumentsRepo(address(_boa)).currentState(ia) ==
                uint8(DocumentsRepo.BODStates.Established),
            "IA not established"
        );
        _;
    }

    // ####################
    // ##   SHA Rights   ##
    // ####################

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyEstablished(ia) withinReviewPeriod(ia) {
        address mock = _boa.mockResultsOfIA(ia);
        if (mock == address(0)) {
            mock = _boa.createMockResults(ia, caller);

            IAccessControl(mock).init(
                caller,
                address(this),
                address(_rc),
                address(_gk)
            );
            IBookSetting(mock).setIA(ia);
            IBookSetting(mock).setBOS(address(_bos));
            IBookSetting(mock).setROM(address(_rom));

            IMockResults(mock).createMockGM();
        }

        IBookSetting(mock).setBOH(address(_boh));

        _addAlongDeal(dragAlong, ia, mock, sn, shareNumber, paid, par, caller);

        bytes32 alongSN = _createAlongDealSN(ia, sn, dragAlong, shareNumber);

        _createAlongDeal(ia, sn, alongSN, paid, par);

        _lockDealSubject(ia, alongSN, par);

        if (!dragAlong)
            ISigPage(ia).signDeal(alongSN.seqOfDeal(), caller, sigHash);
    }

    function _addAlongDeal(
        bool dragAlong,
        address ia,
        address mock,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint40 caller
    ) private {
        uint40 drager = sn.sellerOfDeal();

        address term = dragAlong
            ? _getSHA().getTerm(
                uint8(ShareholdersAgreement.TermTitle.DRAG_ALONG)
            )
            : _getSHA().getTerm(
                uint8(ShareholdersAgreement.TermTitle.TAG_ALONG)
            );

        require(ITerm(term).isTriggered(ia, sn), "not triggered");

        require(
            IAlongs(term).isLinked(drager, shareNumber.shareholder()),
            "drager and target shareholder NOT linked"
        );

        require(
            !ISigPage(ia).isInitSigner(shareNumber.shareholder()),
            "follower is an InitSigner of IA"
        );

        if (dragAlong) {
            require(caller == drager, "caller is not drager of DragAlong");
            require(
                IAlongs(term).priceCheck(ia, sn, shareNumber, caller),
                "price NOT satisfied"
            );
        } else
            require(
                caller == shareNumber.shareholder(),
                "caller is not shareholder of TagAlong"
            );

        // test quota of alongDeal and update mock results
        IMockResults(mock).addAlongDeal(
            IAlongs(term).linkRule(drager),
            shareNumber,
            _rom.basedOnPar() ? par : paid
        );
    }

    function _createAlongDealSN(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber
    ) private view returns (bytes32) {
        uint8 typeOfDeal = (dragAlong)
            ? uint8(InvestmentAgreement.TypeOfDeal.DragAlong)
            : uint8(InvestmentAgreement.TypeOfDeal.TagAlong);

        uint40 buyer = sn.buyerOfDeal();

        return
            createDealSN(
                shareNumber.class(),
                IInvestmentAgreement(ia).counterOfDeals() + 1,
                typeOfDeal,
                shareNumber.shareholder(),
                buyer,
                _rom.groupRep(buyer),
                shareNumber.ssn(),
                sn.priceOfDeal(),
                sn.seqOfDeal()
            );
    }

    function _createAlongDeal(
        address ia,
        bytes32 sn,
        bytes32 snOfAlong,
        uint64 paid,
        uint64 par
    ) private {
        uint48 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            sn.seqOfDeal()
        );

        IInvestmentAgreement(ia).createDeal(snOfAlong, paid, par, closingDate);
    }

    function _lockDealSubject(
        address ia,
        bytes32 alongSN,
        uint64 par
    ) private returns (bool flag) {
        if (IInvestmentAgreement(ia).lockDealSubject(alongSN.seqOfDeal())) {
            _bos.decreaseCleanPar(alongSN.ssnOfDeal(), par);
            flag = true;
        }
    }

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyEstablished(ia) withinReviewPeriod(ia) {
        require(caller == sn.buyerOfDeal(), "caller NOT buyer");

        address mock = _boa.mockResultsOfIA(ia);
        require(mock > address(0), "no MockResults are found for IA");

        uint16 seq = sn.seqOfDeal();
        uint64 amount;

        if (_rom.basedOnPar()) {
            (, , amount, , ) = IInvestmentAgreement(ia).getDeal(seq);
        } else {
            (, amount, , , ) = IInvestmentAgreement(ia).getDeal(seq);
        }

        IMockResults(mock).mockDealOfBuy(sn, amount);

        ISigPage(ia).signDeal(sn.seqOfDeal(), caller, sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyEstablished(ia) withinReviewPeriod(ia) {
        require(
            caller == shareNumber.shareholder(),
            "caller is not shareholder"
        );

        require(
            !ISigPage(ia).isInitSigner(caller),
            "caller is an InitSigner of IA"
        );

        address ad = _getSHA().getTerm(
            uint8(ShareholdersAgreement.TermTitle.ANTI_DILUTION)
        );

        uint64 giftPar = IAntiDilution(ad).giftPar(sn, shareNumber);
        uint40[] memory obligors = IAntiDilution(ad).obligors(
            shareNumber.class()
        );

        _createGiftDeals(ia, sn, giftPar, obligors, caller, sigHash);
    }

    function _createGiftDeals(
        address ia,
        bytes32 sn,
        uint64 giftPar,
        uint40[] memory obligors,
        uint40 caller,
        bytes32 sigHash
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _rom.sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                (bytes32 snOfGiftDeal, uint64 result) = _createGift(
                    ia,
                    sn,
                    sharesInHand[j],
                    giftPar,
                    caller
                );

                ISigPage(ia).signDeal(
                    snOfGiftDeal.seqOfDeal(),
                    caller,
                    sigHash
                );

                giftPar = result;
                if (giftPar == 0) break;
            }
            if (giftPar == 0) break;
        }
        require(giftPar == 0, "obligors have not enough parValue");
    }

    function _createGift(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 giftPar,
        uint40 caller
    ) private returns (bytes32 snOfGiftDeal, uint64 result) {
        uint64 targetCleanPar = _bos.cleanPar(shareNumber.ssn());

        uint64 lockAmount;

        if (targetCleanPar != 0) {
            snOfGiftDeal = _createGiftDealSN(ia, sn, shareNumber, caller);

            uint48 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
                sn.seqOfDeal()
            );

            lockAmount = (targetCleanPar < giftPar) ? targetCleanPar : giftPar;

            IInvestmentAgreement(ia).createDeal(
                snOfGiftDeal,
                lockAmount,
                lockAmount,
                closingDate
            );

            if (
                IInvestmentAgreement(ia).lockDealSubject(
                    snOfGiftDeal.seqOfDeal()
                )
            ) {
                _bos.decreaseCleanPar(shareNumber.ssn(), lockAmount);
            }
        }
        result = giftPar - lockAmount;
    }

    function _createGiftDealSN(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) private view returns (bytes32) {
        return
            createDealSN(
                shareNumber.class(),
                IInvestmentAgreement(ia).counterOfDeals() + 1,
                uint8(InvestmentAgreement.TypeOfDeal.FreeGift),
                shareNumber.shareholder(),
                caller,
                _rom.groupRep(caller),
                shareNumber.ssn(),
                0,
                sn.seqOfDeal()
            );
    }

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint40 caller
    ) external onlyDK {
        require(caller == sn.buyerOfDeal(), "caller is not buyer");

        uint16 seq = sn.seqOfDeal();

        IInvestmentAgreement(ia).takeGift(seq);

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(seq);

        uint32 ssn = sn.ssnOfDeal();

        _bos.increaseCleanPar(ssn, paid);

        _bos.transferShare(ssn, paid, par, sn.buyerOfDeal(), 0);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 snOfOD,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyEstablished(ia) withinReviewPeriod(ia) {
        require(!ISigPage(ia).isInitSigner(caller), "caller is an init signer");

        require(
            _getSHA().isRightholderOfFR(snOfOD.typeOfDeal(), caller),
            "NOT first refusal rightholder"
        );

        // ==== create FR deal in IA ====
        bytes32 snOfFR = _createFRDeal(ia, snOfOD, caller);

        ISigPage(ia).signDeal(snOfFR.seqOfDeal(), caller, sigHash);

        // ==== record FR deal in frDeals ====
        address frd = _boa.frDealsOfIA(ia);
        if (frd == address(0)) {
            frd = _boa.createFRDeals(ia, caller);
            IAccessControl(frd).init(
                caller,
                address(this),
                address(_rc),
                address(_gk)
            );
            IBookSetting(frd).setROM(address(_rom));
        }

        IFirstRefusalDeals(frd).execFirstRefusalRight(
            snOfOD.seqOfDeal(),
            snOfFR.seqOfDeal(),
            caller
        );
    }

    function _createFRDeal(
        address ia,
        bytes32 snOfOD,
        uint40 caller
    ) private returns (bytes32 snOfFR) {
        uint32 ssnOfOD = snOfOD.ssnOfDeal();

        bytes32 shareNumber;

        if (ssnOfOD != 0) (shareNumber, , , , ) = _bos.getShare(ssnOfOD);

        uint16 seq = IInvestmentAgreement(ia).counterOfDeals() + 1;
        uint16 seqOfOD = snOfOD.seqOfDeal();

        snOfFR = createDealSN(
            snOfOD.class(),
            seq,
            ssnOfOD == 0
                ? uint8(InvestmentAgreement.TypeOfDeal.PreEmptive)
                : uint8(InvestmentAgreement.TypeOfDeal.FirstRefusal),
            shareNumber.shareholder(),
            caller,
            _rom.groupRep(caller),
            shareNumber.ssn(),
            snOfOD.priceOfDeal(),
            seqOfOD
        );

        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(
            seqOfOD
        );

        uint48 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            seqOfOD
        );

        IInvestmentAgreement(ia).createDeal(snOfFR, paid, par, closingDate);
    }

    function createDealSN(
        uint16 class,
        uint16 seq,
        uint8 typeOfDeal,
        uint40 seller,
        uint40 buyer,
        uint40 group,
        uint32 ssn,
        uint32 unitPrice,
        uint16 preSeq
    ) public pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.seqToSN(0, class);
        _sn = _sn.seqToSN(2, seq);
        _sn[4] = bytes1(typeOfDeal);
        _sn = _sn.acctToSN(5, seller);
        _sn = _sn.acctToSN(10, buyer);
        _sn = _sn.acctToSN(15, group);
        _sn = _sn.ssnToSN(20, ssn);
        _sn = _sn.ssnToSN(24, unitPrice);
        _sn = _sn.seqToSN(28, preSeq);

        sn = _sn.bytesToBytes32();
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfOD,
        uint16 ssnOfFR,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyEstablished(ia) afterReviewPeriod(ia) {
        uint16 ssnOfOD = snOfOD.seqOfDeal();

        if (
            snOfOD.typeOfDeal() ==
            uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease)
        )
            require(
                _rom.groupRep(caller) == _rom.controllor(),
                "caller not belong to controller group"
            );
        else require(caller == snOfOD.sellerOfDeal(), "not seller of Deal");

        uint64 ratio = _acceptFR(ia, ssnOfOD, ssnOfFR);

        _updateFRDeal(ia, ssnOfOD, ssnOfFR, ratio);

        IInvestmentAgreement(ia).lockDealSubject(ssnOfFR);

        ISigPage(ia).signDeal(ssnOfFR, caller, sigHash);
    }

    function _acceptFR(
        address ia,
        uint16 ssnOfOD,
        uint16 ssnOfFR
    ) private returns (uint64 ratio) {
        address frDeals = _boa.frDealsOfIA(ia);

        ratio = IFirstRefusalDeals(frDeals).acceptFirstRefusal(
            ssnOfOD,
            ssnOfFR
        );
    }

    function _updateFRDeal(
        address ia,
        uint16 ssnOfOD,
        uint16 ssnOfFR,
        uint64 ratio
    ) private {
        (, uint64 paid, uint64 par, , ) = IInvestmentAgreement(ia).getDeal(
            ssnOfOD
        );
        uint48 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            ssnOfOD
        );

        par = (par * ratio) / 10000;
        paid = (paid * ratio) / 10000;

        IInvestmentAgreement(ia).updateDeal(ssnOfFR, paid, par, closingDate);
    }
}
