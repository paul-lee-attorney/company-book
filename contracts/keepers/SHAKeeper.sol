/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/terms/interfaces/IAntiDilution.sol";
import "../books/boh/interfaces/ITerm.sol";

import "../books/boa/interfaces/IInvestmentAgreement.sol";
import "../books/boa/InvestmentAgreement.sol";

import "../books/boh/terms/interfaces/IAlongs.sol";
import "../books/boh/terms/interfaces/IFirstRefusal.sol";

import "../common/components/interfaces/ISigPage.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";
import "../common/lib/ArrayUtils.sol";

contract SHAKeeper is BOASetting, SHASetting, BOSSetting {
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinReviewPeriod(address ia, uint32 sigDate) {
        require(_boa.reviewDeadlineOf(ia) >= sigDate, "missed review period");
        _;
    }

    // modifier withinProposePeriod(address ia, uint32 sigDate) {
    //     require(_boa.reviewDeadlineOf(ia) < sigDate, "still in review period");
    //     require(_boa.votingDeadlineOf(ia) >= sigDate, "missed voting deadline");
    //     _;
    // }

    modifier onlyExecuted(address ia) {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Executed),
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
        uint256 parValue,
        uint256 paidPar,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        onlyExecuted(ia)
        withinReviewPeriod(ia, sigDate)
    {
        _addAlongDeal(
            dragAlong,
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            caller,
            sigDate
        );

        bytes32 alongSN = _createAlongDeal(ia, sn, dragAlong, shareNumber);

        _updateAlongDeal(ia, sn, alongSN, parValue, paidPar);

        _lockDealSubject(ia, alongSN, parValue, sigDate);

        if (!dragAlong)
            ISigPage(ia).signDeal(
                alongSN.sequenceOfDeal(),
                caller,
                sigDate,
                sigHash
            );
    }

    function _addAlongDeal(
        bool dragAlong,
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint40 caller,
        uint32 sigDate
    ) private {
        uint40 drager = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        address term = dragAlong
            ? _getSHA().getTerm(uint8(EnumsRepo.TermTitle.DRAG_ALONG))
            : _getSHA().getTerm(uint8(EnumsRepo.TermTitle.TAG_ALONG));

        require(
            ITerm(term).isTriggered(ia, sn.sequenceOfDeal()),
            "not triggered"
        );

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

    function _createAlongDeal(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber
    ) private returns (bytes32 aSN) {
        uint8 typeOfDeal = dragAlong
            ? uint8(EnumsRepo.TypeOfDeal.DragAlong)
            : uint8(EnumsRepo.TypeOfDeal.TagAlong);

        aSN = IInvestmentAgreement(ia).createDeal(
            typeOfDeal,
            shareNumber,
            shareNumber.class(),
            sn.buyerOfDeal(),
            sn.groupOfBuyer(),
            sn.sequence()
        );
    }

    function _updateAlongDeal(
        address ia,
        bytes32 sn,
        bytes32 alongSN,
        uint256 parValue,
        uint256 paidPar
    ) private {
        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

        IInvestmentAgreement(ia).updateDeal(
            alongSN.sequenceOfDeal(),
            unitPrice,
            parValue,
            paidPar,
            closingDate
        );
    }

    function _lockDealSubject(
        address ia,
        bytes32 alongSN,
        uint256 parValue,
        uint32 sigDate
    ) private returns (bool flag) {
        if (
            IInvestmentAgreement(ia).lockDealSubject(
                alongSN.sequenceOfDeal(),
                sigDate
            )
        ) {
            _bos.decreaseCleanPar(alongSN.shortShareNumberOfDeal(), parValue);
            flag = true;
        }
    }

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint40 drager,
        bool dragAlong,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        onlyExecuted(ia)
        withinReviewPeriod(ia, sigDate)
    {
        require(caller == sn.buyerOfDeal(), "caller NOT buyer");
        _boa.acceptAlongDeal(ia, sn, drager, dragAlong);
        ISigPage(ia).signDeal(sn.sequenceOfDeal(), caller, sigDate, sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        onlyExecuted(ia)
        withinReviewPeriod(ia, sigDate)
    {
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

        uint256 giftPar = IAntiDilution(ad).giftPar(ia, sn, shareNumber);
        uint40[] memory obligors = IAntiDilution(ad).obligors(
            shareNumber.class()
        );

        _createGiftDeals(
            ia,
            sn.sequenceOfDeal(),
            giftPar,
            obligors,
            caller,
            sigDate,
            sigHash
        );
    }

    function _createGiftDeals(
        address ia,
        uint16 ssn,
        uint256 giftPar,
        uint40[] obligors,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _bos.sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                (bytes32 snOfGiftDeal, uint256 result) = _createGift(
                    ia,
                    ssn,
                    sharesInHand[j],
                    giftPar,
                    caller,
                    sigDate
                );

                ISigPage(ia).signDeal(
                    snOfGiftDeal.sequenceOfDeal(),
                    caller,
                    sigDate,
                    sigHash
                );

                // ISigPage(ia).signDeal(
                //     snOfGiftDeal.sequenceOfDeal(),
                //     obligors[i],
                //     sigDate,
                //     sigHash
                // );

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
        uint256 giftPar,
        uint40 caller,
        uint32 sigDate
    ) private returns (bytes32 snOfGiftDeal, uint256 result) {
        uint256 targetCleanPar = _bos.cleanPar(shareNumber.short());

        if (targetCleanPar > 0) {
            snOfGiftDeal = IInvestmentAgreement(ia).createDeal(
                uint8(EnumsRepo.TypeOfDeal.FreeGift),
                shareNumber,
                shareNumber.class(),
                caller,
                _bos.groupNo(caller),
                ssn
            );

            uint256 lockAmount = (targetCleanPar < giftPar)
                ? targetCleanPar
                : giftPar;

            _updateGiftDeal(ia, snOfGiftDeal, lockAmount);

            if (
                IInvestmentAgreement(ia).lockDealSubject(
                    snOfGiftDeal.sequenceOfDeal(),
                    sigDate
                )
            ) {
                _bos.decreaseCleanPar(shareNumber.short(), lockAmount);
                _boa.mockDealOfSell(ia, caller, lockAmount);
            }

            _boa.mockDealOfBuy(
                ia,
                snOfGiftDeal.sequenceOfDeal(),
                caller,
                lockAmount
            );
        }
        result = giftPar - lockAmount;
    }

    function _updateGiftDeal(
        address ia,
        bytes32 snOfGiftDeal,
        uint256 lockAmount
    ) private {
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            snOfGiftDeal.preSSNOfDeal()
        );

        IInvestmentAgreement(ia).updateDeal(
            snOfGiftDeal.sequenceOfDeal(),
            0,
            lockAmount,
            lockAmount,
            closingDate
        );
    }

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint40 caller,
        uint32 sigDate
    ) external currentDate(sigDate) onlyDirectKeeper {
        require(caller == sn.buyerOfDeal(), "caller is not buyer");
        IInvestmentAgreement(ia).takeGift(sn.sequenceOfDeal(), sigDate);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
        onlyExecuted(ia)
        withinReviewPeriod(ia, sigDate)
    {
        require(!ISigPage(ia).isInitSigner(caller), "caller is an init signer");

        address term = _getSHA().getTerm(
            uint8(EnumsRepo.TermTitle.FIRST_REFUSAL)
        );
        require(
            IFirstRefusal(term).isRightholder(sn.typeOfDeal(), caller),
            "NOT first refusal rightholder"
        );

        IInvestmentAgreement(ia).execFirstRefusalRight(
            sn.sequenceOfDeal(),
            _getSHA().basedOnPar(),
            caller,
            sigDate,
            sigHash
        );
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 sn,
        uint40 caller,
        uint32 acceptDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(acceptDate)
        onlyExecuted(ia)
        withinReviewPeriod(ia, acceptDate)
    {
        if (sn.typeOfDeal() == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease))
            require(
                _bos.groupNo(caller) == _bos.controller(),
                "caller not belong to controller group"
            );
        else
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
}
