/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/interfaces/IAgreement.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SafeMath.sol";
import "../common/lib/SNParser.sol";

import "../common/components/interfaces/ISigPage.sol";

import "../common/components/EnumsRepo.sol";

import "../common/utils/Context.sol";

contract BOMKeeper is
    EnumsRepo,
    BOASetting,
    BOMSetting,
    SHASetting,
    BOOSetting
{
    using SafeMath for uint256;
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body, uint32 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(
        address ia,
        uint32 proposeDate,
        uint32 caller
    )
        external
        onlyDirectKeeper
        onlyPartyOf(ia, caller)
        currentDate(proposeDate)
    {
        _bom.proposeMotion(ia, proposeDate, caller);
    }

    function voteCounting(address ia, uint32 caller)
        external
        onlyDirectKeeper
        onlyPartyOf(ia, caller)
    {
        _bom.voteCounting(ia);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        uint32 againstVoter,
        uint32 caller
    ) external onlyDirectKeeper currentDate(exerciseDate) {
        bytes32 shareNumber = IAgreement(ia).shareNumberOfDeal(
            sn.sequenceOfDeal()
        );

        require(caller == shareNumber.shareholder(), "NOT Seller of the Deal");

        (, uint256 unitPrice, , , uint32 closingDate, , ) = IAgreement(ia)
            .getDeal(sn.sequenceOfDeal());

        (uint256 parValue, uint256 paidPar) = _bom.requestToBuy(
            ia,
            sn,
            exerciseDate,
            againstVoter
        );

        uint8 closingDays = uint8((closingDate - exerciseDate + 42300) / 84600);

        bytes32 snOfOpt = _boo.createOption(
            1,
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
