/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfMotions {
    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(address indexed ia, bytes32 sn);

    event Vote(
        address indexed ia,
        uint40 voter,
        uint8 atitude,
        uint256 voteAmt
    );

    event VoteCounting(address indexed ia, uint8 result);

    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(
        address ia,
        uint256 votingDeadline,
        uint40 submitter
    ) external;

    function castVote(
        address ia,
        uint8 attitude,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function voteCounting(address ia, uint32 sigDate) external;

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate
    ) external view returns (uint256 parValue, uint256 paidPar);

    //##################
    //##    读接口    ##
    //##################

    function votingRule(address ia) external view returns (bytes32);

    function state(address ia) external view returns (uint8);

    function votedYea(address ia, uint40 acct) external view returns (bool);

    function votedNay(address ia, uint40 acct) external view returns (bool);

    function getYea(address ia)
        external
        view
        returns (uint40[] membersOfYea, uint256 supportPar);

    function getNay(address ia)
        external
        view
        returns (uint40[] membersOfNay, uint256 againstPar);

    function sumOfVoteAmt(address ia) external view returns (uint256);

    function isVoted(address ia, uint40 acct) external view returns (bool);

    function getVote(address ia, uint40 acct)
        external
        view
        returns (
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        );

    function isPassed(address ia) external view returns (bool);

    function isRejected(address ia) external view returns (bool);
}
