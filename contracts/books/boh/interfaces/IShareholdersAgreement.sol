/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IShareholdersAgreement {
    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[15] templates) external;

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    // ======== VotingRule ========
    function setVotingBaseOnPar() external;

    function setRule(
        uint8 typeOfVote,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy,
        uint8 votingDays,
        uint8 execDaysForPutOpt
    ) external;

    function finalizeSHA() external;

    function kill() external;

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) external view returns (bool);

    function isTitle(uint8 title) external view returns (bool);

    function isBody(address addr) external view returns (bool);

    function titles() external view returns (uint8[]);

    function bodies() external view returns (address[]);

    function getTerm(uint8 title) external view returns (address body);

    function tempOfTitle(uint8 title) external view returns (address);

    // ======== VotingRule ========

    function votingRules(uint8 typeOfVote) external view returns (bytes32);

    function basedOnPar() external view returns (bool);

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external returns (bool);
}
