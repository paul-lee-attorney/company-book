/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfMotions {
    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(address ia, uint256 votingDeadline) external;

    function supportMotion(address ia) external;

    function againstMotion(address ia) external;

    function voteCounting(address ia) external;

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        address agianstVoter
    ) external returns (uint256 parValue, uint256 paidPar);

    function suspendVoting(address ia) external;

    function resumeVoting(address ia) external;

    //##################
    //##    读接口    ##
    //##################

    function votingRule(address ia) external view returns (uint32);

    function votingDeadline(address ia) external view returns (uint256);

    function state(address ia) external view returns (uint8);

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

    function sumOfVoteAmt(address ia) external view returns (uint256);

    function isVoted(address ia, address acct) external view returns (bool);

    function getVote(address ia, address acct)
        external
        view
        returns (
            bool attitude,
            uint256 date,
            uint256 amount
        );

    function isProposed(address ia) external view returns (bool);

    function isPassed(address ia) external view returns (bool);

    function isRejected(address ia) external view returns (bool);
}
