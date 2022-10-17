// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/components/IMeetingMinutes.sol";

import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/MotionsRepo.sol";

import "./IBODKeeper.sol";

contract BODKeeper is
    IBODKeeper,
    BODSetting,
    SHASetting,
    BOMSetting,
    BOSSetting
{

    function appointDirector(
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) external onlyManager(1) {
        require(
            _getSHA().boardSeatsQuotaOf(appointer) >
                _bod.appointmentCounter(appointer),
            "BODKeeper.appointDirector: board seats quota used out"
        );

        if (title == uint8(EnumsRepo.TitleOfDirectors.Chairman)) {
            require(
                _getSHA().appointerOfChairman() == appointer,
                "BODKeeper.appointDirector: has no appointment right"
            );

            require(
                _bod.whoIs(title) == 0 || _bod.whoIs(title) == candidate,
                "BODKeeper.appointDirector: current Chairman shall quit first"
            );
        } else if (title == uint8(EnumsRepo.TitleOfDirectors.ViceChairman)) {
            require(
                _getSHA().appointerOfViceChairman() == appointer,
                "BODKeeper.appointDirector: has no appointment right"
            );
            require(
                _bod.whoIs(title) == 0 || _bod.whoIs(title) == candidate,
                "BODKeeper.appointDirector: current ViceChairman shall quit first"
            );
        } else if (title != uint8(EnumsRepo.TitleOfDirectors.Director)) {
            revert("BODKeeper.appointDirector: there is not such title for candidate");
        }

        _bod.appointDirector(appointer, candidate, title);
    }

    function removeDirector(uint40 director, uint40 appointer)
        external
        onlyManager(1)
    {
        require(_bod.isDirector(director), "BODKeeper.removeDirector: appointer is not a member");
        require(
            _bod.appointerOfDirector(director) == appointer,
            "BODKeeper.reoveDirector: caller is not appointer"
        );

        _bod.removeDirector(director);
    }

    function quitPosition(uint40 director) external onlyManager(1) {
        require(_bod.isDirector(director), "BODKeeper.quitPosition: appointer is not a member");

        _bod.removeDirector(director);
    }

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyManager(1)
    {
        require(_bos.isMember(nominator), "BODKeeper.nominateDirector: nominator is not a member");
        _bom.nominateDirector(candidate, nominator);
    }

    function takePosition(uint40 candidate, uint256 motionId)
        external
        onlyManager(1)
    {
        require(IMeetingMinutes(address(_bom)).isPassed(motionId), "BODKeeper.takePosition: candidate not be approved");

        MotionsRepo.Head memory head = IMeetingMinutes(address(_bom)).headOf(motionId);

        require(
            head.executor == candidate,
            "BODKeeper.takePosition: caller is not the candidate"
        );

        _bod.takePosition(candidate, head.submitter);
    }

    // ==== resolution ====

    function entrustDelegate(
        uint40 caller,
        uint40 delegate,
        uint256 actionId
    ) external onlyManager(1) directorExist(caller) directorExist(delegate) {
        IMeetingMinutes(address(_bod)).entrustDelegate(caller, delegate, actionId);
    }

    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter
    ) external onlyManager(1) directorExist(submitter) {
        IMeetingMinutes(address(_bod)).proposeAction(actionType, targets, values, params, desHash, submitter);
    }

    function castVote(
        uint256 actionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) directorExist(caller) {
        IMeetingMinutes(address(_bod)).castVote(actionId, attitude, caller, sigHash);
    }

    function voteCounting(uint256 actionId, uint40 caller)
        external
        onlyManager(1)
        directorExist(caller)
    {
        IMeetingMinutes(address(_bod)).voteCounting(actionId);
    }

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 caller
    ) external directorExist(caller) returns (uint256) {
        require(!_rc.isContract(caller), "caller is not an EOA");
        return IMeetingMinutes(address(_bod)).execAction(actionType, targets, values, params, desHash);
    }

}
