/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// import "../books/boa//IInvestmentAgreement.sol";

import "../common/ruting/BOSSetting.sol";
// import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";

// import "../common/ruting/BOOSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";

// import "../common/components/ISigPage.sol";

import "../common/lib/EnumsRepo.sol";

import "./IBODKeeper.sol";

contract BODKeeper is
    IBODKeeper,
    BODSetting,
    SHASetting,
    BOMSetting,
    BOSSetting
{
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################
    // modifier onlyPartyOf(address body, uint40 caller) {
    //     require(ISigPage(body).isParty(caller), "NOT Party of Doc");
    //     _;
    // }
    // modifier notPartyOf(address body, uint40 caller) {
    //     require(!ISigPage(body).isParty(caller), "Party has no voting right");
    //     _;
    // }
    // ##################
    // ##   Wite I/O   ##
    // ##################

    function appointDirector(
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) external onlyDirectKeeper {
        require(
            _getSHA().boardSeatsQuotaOf(appointer) >
                _bod.appointmentCounter(appointer),
            "board seats quota used out"
        );

        if (title == uint8(EnumsRepo.TitleOfDirectors.Chairman)) {
            require(
                _getSHA().appointerOfChairman() == appointer,
                "has no appointment right"
            );

            require(
                _bod.whoIs(title) == candidate,
                "current Chairman shall quit first"
            );
        } else if (title == uint8(EnumsRepo.TitleOfDirectors.ViceChairman)) {
            require(
                _getSHA().appointerOfViceChairman() == appointer,
                "has no appointment right"
            );
            require(
                _bod.whoIs(title) == candidate,
                "current ViceChairman shall quit first"
            );
        } else if (title != uint8(EnumsRepo.TitleOfDirectors.Director)) {
            revert("there is not such title for candidate");
        }

        _bod.appointDirector(appointer, candidate, title);
    }

    function removeDirector(uint40 director, uint40 appointer)
        external
        onlyDirectKeeper
    {
        require(_bod.isDirector(director), "appointer is not a member");
        require(
            _bod.appointerOfDirector(director) == appointer,
            "caller is not appointer"
        );

        _bod.removeDirector(director);
    }

    function quitPosition(uint40 director) external onlyDirectKeeper {
        require(_bod.isDirector(director), "appointer is not a member");

        _bod.removeDirector(director);
    }

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyDirectKeeper
    {
        require(_bos.isMember(nominator), "nominator is not a member");
        _bom.nominateDirector(candidate, nominator);
    }

    function takePosition(uint40 candidate, uint256 motionId)
        external
        onlyDirectKeeper
    {
        require(_bom.isPassed(motionId), "candidate not be approved");

        require(
            bytes32(motionId).candidateOfMotion() == candidate,
            "caller is not the candidate"
        );

        _bod.takePosition(candidate);
    }
}
