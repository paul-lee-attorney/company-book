// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

interface IBookOfMotions {
    //##############
    //##  Event   ##
    //##############

    event VoteCounting(uint256 indexed motionId, uint8 result);

    //##################
    //##    写接口    ##
    //##################

    function authorizeToPropose(
        uint40 rightholder,
        uint40 delegate,
        uint256 actionId
    ) external;

    function nominateDirector(uint40 candidate, uint40 nominator) external;

    function proposeMotion(address ia, uint40 submitter) external;

    // function proposeAction(
    //     uint8 actionType,
    //     address[] target,
    //     bytes32[] params,
    //     bytes32 desHash,
    //     uint40 submitter
    // ) external;

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 motionId) external;

    // function execAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash
    // ) external returns (uint256);

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        returns (uint64 paid, uint64 par);

    //##################
    //##    读接口    ##
    //##################

    function serialNumber(uint256 motionId) external view returns (bytes32);

    function votingRule(uint256 motionId) external view returns (bytes32);

    function state(uint256 motionId) external view returns (uint8);

    function votedYea(uint256 motionId, uint40 acct)
        external
        view
        returns (bool);

    function votedNay(uint256 motionId, uint40 acct)
        external
        view
        returns (bool);

    function getYea(uint256 motionId)
        external
        view
        returns (uint40[] memory membersOfYea, uint64 supportPar);

    function getNay(uint256 motionId)
        external
        view
        returns (uint40[] memory membersOfNay, uint64 againstPar);

    function sumOfVoteAmt(uint256 motionId) external view returns (uint64);

    function isVoted(uint256 motionId, uint40 acct)
        external
        view
        returns (bool);

    function getVote(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        );

    function isPassed(uint256 motionId) external view returns (bool);

    function isRejected(uint256 motionId) external view returns (bool);
}
