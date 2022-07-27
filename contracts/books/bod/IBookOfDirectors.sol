/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

interface IBookOfDirectors {
    event SetMaxNumOfDirectors(uint8 num);

    event AddDirector(
        uint40 acct,
        uint8 title,
        uint40 appointer,
        uint32 inaugurationDate,
        uint32 expirationDate
    );

    event RemoveDirector(uint40 userNo, uint8 title);

    event VoteCounting(uint256 indexed motionId, uint8 result);

    //##################
    //##    写接口    ##
    //##################

    function setMaxNumOfDirectors(uint8 num) external;

    function appointDirector(
        uint40 appointer,
        uint40 candidate,
        uint8 title
    ) external;

    function takePosition(uint40 candidate, uint40 nominator) external;

    function removeDirector(uint40 acct) external;

    // ======== Motions ========

    // function proposeAction(
    //     uint8 actionType,
    //     address[] target,
    //     bytes[] params,
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

    //##################
    //##    读接口    ##
    //##################

    // ======== Motions ========

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

    function getYea(uint256 motionId) external view returns (uint40[], uint64);

    function getNay(uint256 motionId) external view returns (uint40[], uint64);

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

    //======== Director ========

    function maxNumOfDirectors() external view returns (uint8);

    function appointmentCounter(uint40 appointer) external view returns (uint8);

    function isDirector(uint40 acct) external view returns (bool);

    function whoIs(uint8 title) external view returns (uint40);

    function titleOfDirector(uint40 acct) external view returns (uint8);

    function appointerOfDirector(uint40 acct) external view returns (uint40);

    function inaugurationDateOfDirector(uint40 acct)
        external
        view
        returns (uint32);

    function expirationDateOfDirector(uint40 acct)
        external
        view
        returns (uint32);

    function qtyOfDirectors() external view returns (uint256);

    function directors() external view returns (uint40[]);
}
