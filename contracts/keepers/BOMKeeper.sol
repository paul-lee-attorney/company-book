/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/interfaces/IInvestmentAgreement.sol";

import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";

import "../common/components/interfaces/ISigPage.sol";

import "../common/lib/EnumsRepo.sol";

contract BOMKeeper is
    BOASetting,
    BOMSetting,
    SHASetting,
    BOOSetting,
    BOSSetting
{
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body, uint40 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    modifier notPartyOf(address body, uint40 caller) {
        require(!ISigPage(body).isParty(caller), "Party has no voting right");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(
        address ia,
        uint32 proposeDate,
        uint40 caller
    )
        external
        onlyDirectKeeper
        onlyPartyOf(ia, caller)
        currentDate(proposeDate)
    {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Executed),
            "InvestmentAgreement not on Executed state"
        );

        require(
            _boa.reviewDeadlineOf(ia) < proposeDate,
            "InvestmentAgreement not passed review procesedure"
        );

        require(
            _boa.votingDeadlineOf(ia) >= proposeDate,
            "missed votingDeadline"
        );

        bytes32 vr = _getSHA().votingRules(_boa.typeOfIA(ia));

        if (vr.ratioHeadOfVR() > 0 || vr.ratioAmountOfVR() > 0)
            _bom.proposeMotion(ia, proposeDate, caller);

        _boa.pushToNextState(ia, proposeDate, caller);
    }

    function supportMotion(
        address ia,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external onlyDirectKeeper currentDate(sigDate) notPartyOf(ia, caller) {
        require(_bos.isMember(caller), "not a shareholder");
        _bom.supportMotion(ia, caller, sigDate, sigHash);
    }

    function againstMotion(
        address ia,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external onlyDirectKeeper currentDate(sigDate) notPartyOf(ia, caller) {
        require(_bos.isMember(caller), "not a shareholder");
        _bom.againstMotion(ia, caller, sigDate, sigHash);
    }

    function voteCounting(
        address ia,
        uint40 caller,
        uint32 sigDate
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) currentDate(sigDate) {
        _bom.voteCounting(ia, sigDate);
        _boa.pushToNextState(ia, sigDate, caller);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        uint40 againstVoter,
        uint40 caller
    ) external onlyDirectKeeper currentDate(exerciseDate) {
        require(
            _bom.state(ia) == uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy),
            "agianst NO need to buy"
        );

        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequenceOfDeal()
        );

        require(caller == shareNumber.shareholder(), "NOT Seller of the Deal");

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

        (uint256 parValue, uint256 paidPar) = _bom.requestToBuy(
            ia,
            sn,
            exerciseDate,
            againstVoter
        );

        uint8 closingDays = uint8((closingDate - exerciseDate + 42300) / 84600);

        bytes32 snOfOpt = _boo.createOption(
            uint8(EnumsRepo.TypeOfOption.Put_Price),
            caller,
            againstVoter,
            exerciseDate,
            1,
            closingDays,
            unitPrice,
            parValue,
            paidPar
        );

        _boo.execOption(snOfOpt.shortOfOpt(), exerciseDate);
        _boo.addFuture(snOfOpt.shortOfOpt(), shareNumber, parValue, paidPar);
    }
}
