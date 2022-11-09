// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import "./IBookOfMotions.sol";

import "../boa/IInvestmentAgreement.sol";

import "../../common/components/ISigPage.sol";
import "../../common/components/MeetingMinutes.sol";

import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/MotionsRepo.sol";
import "../../common/lib/DelegateMap.sol";
import "../../common/lib/BallotsBox.sol";

contract BookOfMotions is IBookOfMotions, MeetingMinutes, BOASetting {
    using SNParser for bytes32;
    using MotionsRepo for MotionsRepo.Repo;
    using DelegateMap for DelegateMap.Map;
    using BallotsBox for BallotsBox.Box;

    enum TypeOfVoting {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STI,
        STE_STI,
        CI_STE_STI,
        CI_STE,
        ElectDirector,
        ReviseAOA,
        NomalAction,
        SpecialAction
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== propose ====

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyManager(1)
    {
        bytes32 rule = _getSHA().votingRules(uint8(TypeOfVoting.ElectDirector));

        MotionsRepo.Head memory head = MotionsRepo.Head({
            typeOfMotion: uint8(TypeOfVoting.ElectDirector),
            state: 0,
            submitter: nominator,
            executor: candidate,
            proposeBN: uint32(block.number),
            weightRegBN: uint32(block.number) +
                uint32(rule.reviewDaysOfVR()) *
                24 *
                _rc.blocksPerHour(),
            voteStartBN: uint32(block.number) +
                uint32(rule.reviewDaysOfVR()) *
                24 *
                _rc.blocksPerHour(),
            voteEndBN: uint32(block.number) +
                uint32(rule.votingDaysOfVR()) *
                24 *
                _rc.blocksPerHour()
        });

        uint256 motionId = uint256(keccak256(abi.encode(head)));

        if (_mm.proposeMotion(motionId, rule, head))
            emit NominateDirector(motionId, candidate, nominator);
    }

    function proposeIA(address ia, uint40 submitter) external onlyManager(1) {
        require(ISigPage(ia).established(), "doc is not established");

        uint256 motionId = uint256(uint160(ia));

        uint8 motionType = _boa.typeOfIA(ia);

        bytes32 rule = _getSHA().votingRules(motionType);

        MotionsRepo.Head memory head = MotionsRepo.Head({
            typeOfMotion: motionType,
            state: 0,
            submitter: submitter,
            executor: 0,
            proposeBN: uint32(block.number),
            weightRegBN: _boa.reviewDeadlineBNOf(ia),
            voteStartBN: _boa.reviewDeadlineBNOf(ia),
            voteEndBN: _boa.votingDeadlineBNOf(ia)
        });

        if (_mm.proposeMotion(motionId, rule, head))
            emit ProposeIA(motionId, ia, submitter);
    }

    // ==== requestToBuy ====

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        onlyManager(1)
        returns (uint64 paid, uint64 par)
    {
        require(
            block.timestamp <
                IInvestmentAgreement(ia).closingDateOfDeal(sn.sequence()),
            "MISSED closing date"
        );

        require(
            block.number <
                _mm.motions[uint256(uint160(ia))].head.voteEndBN +
                    uint32(
                        _mm
                            .motions[uint256(uint160(ia))]
                            .votingRule
                            .execDaysForPutOptOfVR()
                    ) *
                    24 *
                    _rc.blocksPerHour(),
            "MISSED execute deadline"
        );

        (, paid, par, , ) = IInvestmentAgreement(ia).getDeal(sn.sequence());
    }
}
