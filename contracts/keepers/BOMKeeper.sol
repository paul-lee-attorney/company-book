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
    BOOSetting,
    Context
{
    using SafeMath for uint256;
    using SNParser for bytes32;

    // constructor(address bookeeper) public {
    //     init(msg.sender, bookeeper);
    // }

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(_bridgedMsgSender), "NOT Party of Doc");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia, uint32 proposeDate)
        external
        onlyDirectKeeper
        onlyPartyOf(ia)
        currentDate(proposeDate)
    {
        _bom.proposeMotion(ia, proposeDate, _bridgedMsgSender);
        _clearMsgSender();
    }

    function voteCounting(address ia)
        external
        onlyDirectKeeper
        onlyPartyOf(ia)
    {
        _clearMsgSender();
        _bom.voteCounting(ia);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        uint32 againstVoter
    ) external onlyDirectKeeper currentDate(exerciseDate) {
        bytes32 shareNumber = IAgreement(ia).shareNumberOfDeal(
            sn.sequenceOfDeal()
        );

        require(
            _bridgedMsgSender == shareNumber.shareholder(),
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
            _bridgedMsgSender,
            againstVoter,
            exerciseDate,
            1,
            closingDays,
            unitPrice,
            parValue,
            paidPar
        );

        _clearMsgSender();

        _boo.execOption(snOfOpt.shortOfOpt(), exerciseDate);
        _boo.addFuture(snOfOpt.shortOfOpt(), shareNumber, parValue, paidPar);
    }
}
