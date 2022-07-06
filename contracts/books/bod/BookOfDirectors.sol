/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

import "../../common/ruting/SHASetting.sol";

import "../../common/components/MotionsRepo.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "../../common/access/AccessControl.sol";

import "./IBookOfDirectors.sol";

contract BookOfDirectors is IBookOfDirectors, MotionsRepo, SHASetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.BallotsBox;

    struct Director {
        uint8 title; // 1-Chairman; 2-ViceChairman; 3-Director;
        uint40 appointer;
        uint32 inaugurationBN;
        uint32 expirationBN;
    }

    // userNo => Director
    mapping(uint40 => Director) private _directors;

    // appointer => numOfDirector nominated;
    mapping(uint40 => uint8) private _appointmentCounter;

    // title => userNo
    mapping(uint8 => uint40) private _whoIs;

    EnumerableSet.UintSet private _directorsUserNoList;

    uint8 private _maxNumOfDirectors;

    //####################
    //##    modifier    ##
    //####################

    modifier directorExist(uint40 acct) {
        require(_directorsUserNoList.contains(acct), "not a director");
        require(
            _directors[acct].expirationBN >= now + 15 minutes,
            "tenure expired"
        );
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function proposeAction(
        uint8 actionType,
        address[] targets,
        bytes[] params,
        bytes32 desHash,
        uint40 submitter
    ) external onlyDirectKeeper {
        require(
            _directorsUserNoList.contains(submitter),
            "submitter is not Director"
        );
        require(
            _directors[submitter].expirationBN >= block.number,
            "tenure expired"
        );

        uint256 actionId = _hashAction(actionType, targets, params, desHash);

        bytes32 rule = _getSHA().votingRules(actionType);

        bytes32 sn = _createSN(
            actionType,
            submitter,
            uint32(block.timestamp),
            uint32(block.number) +
                (uint32(rule.votingDaysOfVR()) * 24 * _rc.blocksPerHour()),
            uint32(block.number),
            0
        );

        _proposeMotion(
            actionId,
            rule,
            sn,
            actionType,
            targets,
            params,
            desHash
        );
    }

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper {
        require(_directorsUserNoList.contains(caller), "not a director");
        require(
            _directors[caller].expirationBN >= block.number,
            "tenure expired"
        );

        Motion storage motion = _motions[motionId];

        require(
            _directors[caller].inaugurationBN <=
                motion.sn.weightRegBlockOfMotion(),
            "not a Director at weight registration BN"
        );

        _castVote(motionId, attitude, caller, sigHash, 1);
    }

    function voteCounting(uint256 motionId)
        external
        onlyDirectKeeper
        onlyProposed(motionId)
        afterExpire(motionId)
    {
        Motion storage motion = _motions[motionId];

        uint256 threshold = motion.votingRule.ratioHeadOfVR();

        require(threshold > 0, "no threshold defined in voting rule");

        uint40 vetoHolder = motion.votingRule.vetoHolderOfVR();

        if (vetoHolder > 0 && !motion.box.supportVoters.contains(vetoHolder)) {
            motion.state = uint8(EnumsRepo.StateOfMotion.Rejected);
        } else {
            motion.state = (motion.box.supportVoters.length() * 10000) /
                _directorsUserNoList.length() >
                threshold
                ? uint8(EnumsRepo.StateOfMotion.Passed)
                : uint8(EnumsRepo.StateOfMotion.Rejected);
        }

        emit VoteCounting(motionId, motion.state);
    }

    // ======== Directors ========

    function setMaxNumOfDirectors(uint8 num) external onlyKeeper {
        _maxNumOfDirectors = num;
        emit SetMaxNumOfDirectors(num);
    }

    function appointDirector(
        uint40 appointer,
        uint40 candidate,
        uint8 title
    ) external onlyDirectKeeper {
        _addDirector(candidate, appointer, title);
    }

    function _addDirector(
        uint40 candidate,
        uint40 appointer,
        uint8 title
    ) private {
        if (!_directorsUserNoList.contains(candidate))
            require(
                _directorsUserNoList.length() < _maxNumOfDirectors,
                "number of directors overflow"
            );

        if (appointer > 0) _appointmentCounter[appointer]++;

        uint32 inaugurationBN = uint32(block.number);

        uint32 expirationBN = inaugurationBN +
            uint32(_getSHA().tenureOfBoard()) *
            8760 *
            _rc.blocksPerHour();

        Director storage director = _directors[candidate];

        director.title = title;
        director.appointer = appointer;
        director.inaugurationBN = inaugurationBN;
        director.expirationBN = expirationBN;

        if (title != uint8(EnumsRepo.TitleOfDirectors.Director))
            _whoIs[title] = candidate;

        _directorsUserNoList.add(candidate);

        emit AddDirector(
            candidate,
            title,
            appointer,
            inaugurationBN,
            expirationBN
        );
    }

    function takePosition(uint40 candidate) external onlyDirectKeeper {
        _addDirector(candidate, 0, uint8(EnumsRepo.TitleOfDirectors.Director));
    }

    function removeDirector(uint40 acct) external onlyDirectKeeper {
        if (_directorsUserNoList.remove(acct)) {
            uint8 title = _directors[acct].title;
            if (uint40(_whoIs[title]) == acct) delete _whoIs[title];

            uint40 appointer = _directors[acct].appointer;
            if (appointer > 0) _appointmentCounter[appointer]--;

            delete _directors[acct];

            emit RemoveDirector(acct, title);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function maxNumOfDirectors() external view onlyUser returns (uint8) {
        return _maxNumOfDirectors;
    }

    function appointmentCounter(uint40 appointer)
        external
        view
        onlyUser
        returns (uint8)
    {
        return _appointmentCounter[appointer];
    }

    function isDirector(uint40 acct) external view onlyUser returns (bool) {
        return _directorsUserNoList.contains(acct);
    }

    function inTenure(uint40 acct)
        external
        view
        directorExist(acct)
        onlyUser
        returns (bool)
    {
        return (_directors[acct].expirationBN >= block.number);
    }

    function whoIs(uint8 title) external view onlyUser returns (uint40) {
        require(
            title != uint8(EnumsRepo.TitleOfDirectors.Director),
            "director is not a special title"
        );

        uint40 userNo = _whoIs[title];

        if (_directors[userNo].title != title) userNo = 0;

        return userNo;
    }

    function titleOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint8)
    {
        return _directors[acct].title;
    }

    function appointerOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint40)
    {
        return _directors[acct].appointer;
    }

    function inaugurationBNOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint32)
    {
        return _directors[acct].inaugurationBN;
    }

    function expirationBNOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint32)
    {
        return _directors[acct].expirationBN;
    }

    function qtyOfDirectors() external view onlyUser returns (uint256) {
        return _directorsUserNoList.length();
    }

    function directors() external view onlyUser returns (uint40[]) {
        return _directorsUserNoList.valuesToUint40();
    }
}
