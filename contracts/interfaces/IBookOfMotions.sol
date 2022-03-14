/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfMotions {
    //##############
    //##  Event   ##
    //##############

    event ProposeMotion(
        address indexed ia,
        uint256 votingDeadline,
        address proposedBy
    );

    event Vote(
        address indexed ia,
        address voter,
        bool support,
        uint256 voteAmt
    );

    event VoteCounting(address indexed ia, uint8 docType, uint8 result);

    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(address ia, uint8 votingDays) external;

    function supportMotion(address ia) external;

    function againstMotion(address ia) external;

    function voteCounting(address ia) external;

    //##################
    //##    读接口    ##
    //##################

    function votedYea(address ia, address acct) external returns (bool);

    function votedNay(address ia, address acct) external returns (bool);

    function getYea(address ia)
        external
        view
        returns (address[] membersOfYea, uint256 supportPar);

    function getNay(address ia)
        external
        view
        returns (address[] membersOfNay, uint256 againstPar);

    function haveVoted(address ia, address acct) external returns (bool);

    function getVotedPar(address ia) external returns (uint256);

    function getVoteDate(address ia, address acct)
        external
        view
        returns (uint256 date);

    function isProposed(address ia) external view returns (bool);

    function isPassed(address ia) external view returns (bool);

    function isRejected(address ia) external view returns (bool);
}
