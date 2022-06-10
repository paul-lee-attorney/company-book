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

contract SHAKeeper is BOASetting, SHASetting, BOSSetting {
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinReviewPeriod(address body, uint32 sigDate) {
        require(_boa.reviewDeadlineOf(body) >= sigDate, "missed review period");
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
            dragAlong,
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            caller,
            sigDate
        );

        bytes32 alongSN = _createAlongDeal(
            ia,
            sn,
            dragAlong,
            shareNumber,
            caller,
            sigDate,
            sigHash
        );

        _updateAlongDeal(ia, sn, alongSN, parValue, paidPar);
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
        uint32 drager = IInvestmentAgreement(ia)
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

        ISigPage(ia).backToFinalized(_boa.reviewDeadlineOf(ia));
    }

    function _createAlongDeal(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
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

        if (!dragAlong)
            ISigPage(ia).signDeal(
                sn.sequenceOfDeal(),
                caller,
                sigDate,
                sigHash
            );
    }

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint32 drager,
        bool dragAlong,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    )
        external
        onlyDirectKeeper
        currentDate(sigDate)
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

        require(
            !ISigPage(ia).isInitSigner(caller),
            "caller is an InitSigner of IA"
        );

        address ad = _getSHA().getTerm(
            uint8(EnumsRepo.TermTitle.ANTI_DILUTION)
        );

        require(
            ITerm(ad).isTriggered(ia, sn.sequenceOfDeal()),
            "AntiDilution is not triggered"
        );

        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

        uint256 giftPar = IAntiDilution(ad).giftPar(ia, sn, shareNumber);
        uint32[] memory obligors = IAntiDilution(ad).obligors(
            shareNumber.class()
        );

        _createGiftDeals(
            ia,
            giftPar,
            closingDate,
            obligors,
            caller,
            sigDate,
            sigHash
        );
    }

    function _createGiftDeals(
        address ia,
        uint256 giftPar,
        uint32 closingDate,
        uint32[] obligors,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) private {
        _boa.rejectDoc(ia, sigDate, caller);

        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _bos.sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                uint256 targetCleanPar = _bos.cleanPar(sharesInHand[j].short());

                if (targetCleanPar > 0) {
                    bytes32 snOfGiftDeal = IInvestmentAgreement(ia).createDeal(
                        uint8(EnumsRepo.TypeOfDeal.FreeGift),
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
                            caller,
                            sigDate,
                            sigHash
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
                            caller,
                            sigDate,
                            sigHash
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
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
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
        ISigPage(ia).signDeal(
            snOfGiftDeal.sequenceOfDeal(),
            caller,
            sigDate,
            sigHash
        );
    }

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 sigDate
    ) external currentDate(sigDate) onlyDirectKeeper {
        require(caller == sn.buyerOfDeal(), "caller is not buyer");
        IInvestmentAgreement(ia).takeGift(sn.sequenceOfDeal(), sigDate);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
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
        require(!ISigPage(ia).isInitSigner(caller), "caller is an init signer");

        address term = _getSHA().getTerm(
            uint8(EnumsRepo.TermTitle.FIRST_REFUSAL)
        );
        require(
            IFirstRefusal(term).isRightholder(sn.typeOfDeal(), caller),
            "NOT first refusal rightholder"
        );

        _boa.rejectDoc(ia, sigDate, caller);

        IInvestmentAgreement(ia).execFirstRefusalRight(
            sn.sequenceOfDeal(),
            _getSHA().basedOnPar(),
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
