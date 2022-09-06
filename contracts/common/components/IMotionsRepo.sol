/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

interface IMotionsRepo {
    //##############
    //##  Event   ##
    //##############

    event AuthorizeDelegate(
        uint40 rightholder,
        uint40 delegate,
        uint256 motionId
    );

    event ProposeMotion(
        uint256 indexed motionId,
        uint8 typeOfMotion,
        address[] targets,
        bytes[] params,
        bytes32 desHash,
        bytes32 sn
    );

    event CastVote(
        uint256 indexed motionId,
        uint40 voter,
        uint8 atitude,
        uint64 voteAmt
    );

    event ExecuteAction(uint256 indexed motionId, bool flag);

    //##################
    //##    写接口    ##
    //##################

    // function execAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash
    // ) external  returns (uint256);

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
}
