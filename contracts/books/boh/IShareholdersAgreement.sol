/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IShareholdersAgreement {
    //##############
    //##  Event   ##
    //##############

    event SetTemplate(uint8 indexed title, address tempAdd);

    event CreateTerm(uint8 indexed title, address indexed body, uint40 creator);

    event RemoveTerm(uint8 indexed title);

    // ==== VotingRules ====

    event SetVotingBaseOnPar(bool flag);

    event SetProposalThreshold(uint64 threshold);

    event SetMaxNumOfDirectors(uint8 num);

    event SetTenureOfBoard(uint8 numOfYear);

    event SetAppointerOfChairman(uint40 indexed nominator);

    event SetAppointerOfViceChairman(uint40 indexed nominator);

    event SetBoardSeatsQuotaOf(uint40 indexed nominator, uint8 quota);

    event SetRule(uint8 indexed typeOfVote, bytes32 sn);

    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[15] templates) external;

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    // function finalizeSHA() external;

    // ======== VotingRule ========

    function setVotingBaseOnPar(bool flag) external;

    function setProposalThreshold(uint16 threshold) external;

    function setMaxNumOfDirectors(uint8 num) external;

    function setTenureOfBoard(uint8 numOfYear) external;

    function setAppointerOfChairman(uint40 nominator) external;

    function setAppointerOfViceChairman(uint40 nominator) external;

    function setBoardSeatsQuotaOf(uint40 nominator, uint8 quota) external;

    function setRule(
        uint8 typeOfVote,
        uint40 vetoHolder,
        uint16 ratioHead,
        uint16 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool partyAsConsent,
        bool againstShallBuy,
        uint8 reviewDays,
        uint8 votingDays,
        uint8 execDaysForPutOpt
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function tempOfTitle(uint8 title) external view returns (address);

    function hasTitle(uint8 title) external view returns (bool);

    function isTitle(uint8 title) external view returns (bool);

    function isBody(address addr) external view returns (bool);

    function titles() external view returns (uint8[]);

    function bodies() external view returns (address[]);

    function getTerm(uint8 title) external view returns (address body);

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

    function sumOfBoardSeatsQuota() external view returns (uint8);

    function boardSeatsQuotaOf(uint40 acct) external view returns (uint8);
}
