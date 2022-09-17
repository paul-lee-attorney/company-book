/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/terms/IAntiDilution.sol";
import "../books/boh/terms/ITerm.sol";

import "../books/boa/IInvestmentAgreement.sol";
import "../books/boa/IFirstRefusalDeals.sol";
import "../books/boa/IMockResults.sol";

import "../books/boh/terms/IAlongs.sol";
import "../books/boh/terms/IFirstRefusal.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOCSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is
    ISHAKeeper,
    BOCSetting,
    BOASetting,
    BOSSetting,
    SHASetting
{
    using SNParser for bytes32;

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
            _boa.reviewDeadlineBNOf(ia) < block.number,
            "still within review period"
        );
        _;
    }

    modifier onlyEstablished(address ia) {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Established),
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
        uint64 parValue,
        uint64 paidPar,
        address callerAddr,
        bytes32 sigHash
    ) external onlyManager(1) onlyEstablished(ia) withinReviewPeriod(ia) {
        address mock = _boa.mockResultsOfIA(ia);
        if (mock == address(0)) mock = _boa.createMockResults(ia);

        IBookSetting(mock).setBOC(_boc);
        IBookSetting(mock).setBOH(_boh);

        _addAlongDeal(
            dragAlong,
            ia,
            mock,
            sn,
            shareNumber,
            parValue,
            paidPar,
            callerAddr
        );

        // uint40 caller = _rc.userNo(callerAddr);

        bytes32 alongSN = _createAlongDeal(ia, sn, dragAlong, shareNumber);

        _updateAlongDeal(ia, sn, alongSN, parValue, paidPar);

        _lockDealSubject(ia, alongSN, parValue);

        if (!dragAlong)
            ISigPage(ia).signDeal(
                alongSN.sequence(),
                _rc.userNo(callerAddr),
                sigHash
            );
    }

    function _addAlongDeal(
        bool dragAlong,
        address ia,
        address mock,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar,
        address callerAddr
    ) private {
        uint40 drager = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequence())
            .shareholder();

        address term = dragAlong
            ? _getSHA().getTerm(uint8(EnumsRepo.TermTitle.DRAG_ALONG))
            : _getSHA().getTerm(uint8(EnumsRepo.TermTitle.TAG_ALONG));

        require(ITerm(term).isTriggered(ia, sn), "not triggered");

        require(
            IAlongs(term).isLinked(drager, shareNumber.shareholder()),
            "drager and target shareholder NOT linked"
        );

        require(
            !ISigPage(ia).isInitSigner(shareNumber.shareholder()),
            "follower is an InitSigner of IA"
        );

        uint40 caller = _rc.userNo(callerAddr);

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
            IAlongs(term).linkRule(_boc.groupNo(drager)),
            shareNumber,
            parValue,
            paidPar
        );
    }

    function _createAlongDeal(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber
    ) private returns (bytes32 aSN) {
        uint8 typeOfDeal = (dragAlong)
            ? uint8(EnumsRepo.TypeOfDeal.DragAlong)
            : uint8(EnumsRepo.TypeOfDeal.TagAlong);

        aSN = IInvestmentAgreement(ia).createDeal(
            typeOfDeal,
            shareNumber,
            shareNumber.class(),
            sn.buyerOfDeal(),
            // sn.groupOfBuyer(),
            sn.sequence()
        );
    }

    function _updateAlongDeal(
        address ia,
        bytes32 sn,
        bytes32 alongSN,
        uint64 parValue,
        uint64 paidPar
    ) private {
        uint32 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequence()
        );

        IInvestmentAgreement(ia).updateDeal(
            alongSN.sequence(),
            unitPrice,
            parValue,
            paidPar,
            closingDate
        );
    }

    function _lockDealSubject(
        address ia,
        bytes32 alongSN,
        uint64 parValue
    ) private returns (bool flag) {
        if (IInvestmentAgreement(ia).lockDealSubject(alongSN.sequence())) {
            _bos.decreaseCleanPar(alongSN.ssnOfDeal(), parValue);
            flag = true;
        }
    }

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyEstablished(ia) withinReviewPeriod(ia) {
        require(caller == sn.buyerOfDeal(), "caller NOT buyer");

        address mock = _boa.mockResultsOfIA(ia);
        require(mock > address(0), "no MockResults are found for IA");

        IMockResults(mock).acceptAlongDeal(sn);

        ISigPage(ia).signDeal(sn.sequence(), caller, sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyEstablished(ia) withinReviewPeriod(ia) {
        require(
            caller == shareNumber.shareholder(),
            "caller is not shareholder"
        );

        require(
            !ISigPage(ia).isInitSigner(caller),
            "caller is an InitSigner of IA"
        );

        address ad = _getSHA().getTerm(
            uint8(EnumsRepo.TermTitle.ANTI_DILUTION)
        );

        uint64 giftPar = IAntiDilution(ad).giftPar(ia, sn, shareNumber);
        uint40[] memory obligors = IAntiDilution(ad).obligors(
            shareNumber.class()
        );

        _createGiftDeals(ia, sn.sequence(), giftPar, obligors, caller, sigHash);
    }

    function _createGiftDeals(
        address ia,
        uint16 ssn,
        uint64 giftPar,
        uint40[] obligors,
        uint40 caller,
        bytes32 sigHash
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _bos.sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                (bytes32 snOfGiftDeal, uint64 result) = _createGift(
                    ia,
                    ssn,
                    sharesInHand[j],
                    giftPar,
                    caller
                );

                ISigPage(ia).signDeal(snOfGiftDeal.sequence(), caller, sigHash);

                giftPar = result;
                if (giftPar == 0) break;
            }
            if (giftPar == 0) break;
        }
        require(giftPar == 0, "obligors have not enough parValue");
    }

    function _createGift(
        address ia,
        uint16 ssn,
        bytes32 shareNumber,
        uint64 giftPar,
        uint40 caller
    ) private returns (bytes32 snOfGiftDeal, uint64 result) {
        uint64 targetCleanPar = _bos.cleanPar(shareNumber.ssn());

        if (targetCleanPar > 0) {
            snOfGiftDeal = IInvestmentAgreement(ia).createDeal(
                uint8(EnumsRepo.TypeOfDeal.FreeGift),
                shareNumber,
                shareNumber.class(),
                caller,
                // _boc.groupNo(caller),
                ssn
            );

            uint64 lockAmount = (targetCleanPar < giftPar)
                ? targetCleanPar
                : giftPar;

            _updateGiftDeal(ia, snOfGiftDeal, lockAmount);

            if (
                IInvestmentAgreement(ia).lockDealSubject(
                    snOfGiftDeal.sequence()
                )
            ) {
                _bos.decreaseCleanPar(shareNumber.ssn(), lockAmount);
                // _boa.mockDealOfSell(ia, caller, lockAmount);
            }

            // _boa.mockDealOfBuy(ia, snOfGiftDeal.sequence(), caller, lockAmount);
        }
        result = giftPar - lockAmount;
    }

    function _updateGiftDeal(
        address ia,
        bytes32 snOfGiftDeal,
        uint64 lockAmount
    ) private {
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            snOfGiftDeal.preSeqOfDeal()
        );

        IInvestmentAgreement(ia).updateDeal(
            snOfGiftDeal.sequence(),
            0,
            lockAmount,
            lockAmount,
            closingDate
        );
    }

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint40 caller
    ) external onlyManager(1) {
        require(caller == sn.buyerOfDeal(), "caller is not buyer");
        IInvestmentAgreement(ia).takeGift(sn.sequence());
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 snOfOD,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyEstablished(ia) withinReviewPeriod(ia) {
        require(!ISigPage(ia).isInitSigner(caller), "caller is an init signer");

        address term = _getSHA().getTerm(
            uint8(EnumsRepo.TermTitle.FIRST_REFUSAL)
        );
        require(
            IFirstRefusal(term).isRightholder(snOfOD.typeOfDeal(), caller),
            "NOT first refusal rightholder"
        );

        // ==== create FR deal in IA ====
        bytes32 snOfFR = _createFRDeal(ia, snOfOD, caller);

        ISigPage(ia).signDeal(snOfFR.sequence(), caller, sigHash);

        // ==== record FR deal in frDeals ====
        address frDeals = _boa.frDealsOfIA(ia);
        if (frDeals == address(0)) frDeals = _boa.createFRDeals(ia, caller);

        IFirstRefusalDeals(frDeals).execFirstRefusalRight(
            snOfOD.sequence(),
            snOfFR.sequence(),
            caller
        );
    }

    function _createFRDeal(
        address ia,
        bytes32 snOfOD,
        uint40 caller
    ) private returns (bytes32 snOfFR) {
        uint32 ssnOfOD = snOfOD.ssnOfDeal();

        if (ssnOfOD > 0)
            (bytes32 shareNumber, , , , , ) = _bos.getShare(ssnOfOD);

        snOfFR = IInvestmentAgreement(ia).createDeal(
            ssnOfOD == 0
                ? uint8(EnumsRepo.TypeOfDeal.PreEmptive)
                : uint8(EnumsRepo.TypeOfDeal.FirstRefusal),
            shareNumber,
            snOfOD.class(),
            caller,
            // _boc.groupNo(caller),
            snOfOD.sequence()
        );
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfOD,
        uint16 ssnOfFR,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyEstablished(ia) afterReviewPeriod(ia) {
        uint16 ssnOfOD = snOfOD.sequence();

        if (snOfOD.typeOfDeal() == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease))
            require(
                _boc.groupNo(caller) == _boc.controller(),
                "caller not belong to controller group"
            );
        else
            require(
                caller ==
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(ssnOfOD)
                        .shareholder(),
                "not seller of Deal"
            );

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
        (, uint64 parValue, uint64 paidPar, , ) = IInvestmentAgreement(ia)
            .getDeal(ssnOfOD);
        uint32 unitPrice = IInvestmentAgreement(ia).unitPrice(ssnOfOD);
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(ssnOfOD);

        parValue = (parValue * ratio) / 10000;
        paidPar = (paidPar * ratio) / 10000;

        IInvestmentAgreement(ia).updateDeal(
            ssnOfFR,
            unitPrice,
            parValue,
            paidPar,
            closingDate
        );
    }
}
