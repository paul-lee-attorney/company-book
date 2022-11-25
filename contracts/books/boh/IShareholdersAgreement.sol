// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/ISigPage.sol";

interface IShareholdersAgreement is ISigPage {
    //##############
    //##  Event   ##
    //##############

    event SetTemplate(uint8 indexed title, address tempAdd);

    event CreateTerm(uint8 indexed title, address indexed body);

    event RemoveTerm(uint8 indexed title);

    // ==== VotingRules ====

    event SetGovernanceRule(bytes32 rule);

    event SetVotingRule(uint8 indexed typeOfVote, bytes32 rule);

    event SetBoardSeatsOf(uint40 indexed nominator, uint8 quota);

    event RemoveRule(uint256 seq);

    //##################
    //##    写接口    ##
    //##################

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    function finalizeTerms() external;

    // ======== Rules ========
    function setGovernanceRule(bytes32 rule) external;

    function setVotingRule(bytes32 rule) external;

    function removeRule(uint256 seq) external;

    function setBoardSeatsOf(uint40 nominator, uint8 quota) external;

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) external view returns (bool);

    function qtyOfTerms() external view returns (uint8);

    function titles() external view returns (uint8[] memory);

    function bodies() external view returns (address[] memory);

    function getTerm(uint8 title) external view returns (address);

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view returns (bool);

    // ======== VotingRule ========

    function votingRules(uint8 typeOfVote) external view returns (bytes32);

    function basedOnPar() external view returns (bool);

    function proposalThreshold() external view returns (uint16);

    function maxNumOfDirectors() external view returns (uint8);

    function tenureOfBoard() external view returns (uint8);

    function appointerOfChairman() external view returns (uint40);

    function appointerOfViceChairman() external view returns (uint40);

    function boardSeatsOf(uint40 acct) external view returns (uint8);
}
