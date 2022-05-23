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

    // function setBOS(address bos) external;

    // function setBOM(address bom) external;

    function removeTemplate(uint8 title) external;

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    function setRule(
        uint8 typeOfVote,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy,
        bool basedOnParValue,
        uint8 votingDays,
        uint8 execDaysForPutOpt
    ) external;

    function finalizeSHA() external;

    function kill() external;

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) external view returns (bool);

    function getTerm(uint8 title) external view returns (address body);

    function isTerm(address addr) external view returns (bool);

    function terms() external view returns (address[]);

    function tempOfTitle(uint8 title) external view returns (address);

    function votingRules(uint8 typeOfVote) external view returns (bytes32);

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
