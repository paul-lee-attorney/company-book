/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/interfaces/IAgreement.sol";

import "../common/config/SHASetting.sol";
import "../common/config/BOASetting.sol";
import "../common/config/BOMSetting.sol";
import "../common/config/BOOSetting.sol";

import "../common/lib/SafeMath.sol";
import "../common/lib/serialNumber/ShareSNParser.sol";
import "../common/lib/serialNumber/DealSNParser.sol";
import "../common/lib/serialNumber/VotingRuleParser.sol";
import "../common/lib/serialNumber/OptionSNParser.sol";

import "../common/components/interfaces/ISigPage.sol";

import "../common/components/EnumsRepo.sol";

contract BOMKeeper is
    BOASetting,
    BOMSetting,
    SHASetting,
    BOOSetting,
    EnumsRepo
{
    using SafeMath for uint256;
    using ShareSNParser for bytes32;
    using DealSNParser for bytes32;
    using OptionSNParser for bytes32;
    using VotingRuleParser for bytes32;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(msg.sender), "NOT Party of Doc");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia, uint32 proposeDate)
        external
        onlyPartyOf(ia)
        currentDate(proposeDate)
    {
        _bom.proposeMotion(ia, proposeDate);
    }

    function voteCounting(address ia) external onlyPartyOf(ia) {
        _bom.voteCounting(ia);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        address againstVoter
    ) external currentDate(exerciseDate) {
        // require(IAgreement(ia).isDeal(sn.sequenceOfDeal()), "deal NOT exist");
        // require(sn.typeOfDeal() == 2, "NOT a 3rd party ST Deal");

        bytes32 shareNumber = IAgreement(ia).shareNumberOfDeal(
            sn.sequenceOfDeal()
        );

        require(
            msg.sender == shareNumber.shareholder(),
            "NOT Seller of the Deal"
        );

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
            msg.sender,
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
