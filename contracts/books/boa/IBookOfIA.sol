/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfIA {
    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) external;

    function createDoc(uint8 docType, uint40 creator)
        external
        returns (address body);

    function removeDoc(address body) external;

    function pushToNextState(address body, uint40 caller) external;

    // ======== BookOfIA ========

    function circulateIA(address ia, uint40 submitter) external;

    function mockDealOfSell(
        address ia,
        uint40 seller,
        uint256 amount
    ) external;

    function mockDealOfBuy(
        address ia,
        uint16 ssn,
        uint40 buyer,
        uint256 amount
    ) external;

    function calculateMockResult(address ia) external;

    function proposeIA(
        address ia,
        uint32 proposeDate,
        uint40 caller
    ) external;

    function addAlongDeal(
        address ia,
        bytes32 rule,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint40 caller
    ) external;

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint40 drager,
        bool dragAlong
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function bookName() external view returns (string);

    function template() external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function counterOfDocs() external view returns (uint16);

    function passedReview(address ia) external view returns (bool);

    function isCirculated(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (bytes32[]);

    function getDoc(address body)
        external
        view
        returns (bytes32 sn, bytes32 docHash);

    function currentState(address body) external view returns (uint8);

    function startDateOf(address body) external view returns (uint32);

    function reviewDeadlineBNOf(address body) external view returns (uint32);

    function votingDeadlineBNOf(address body) external view returns (uint32);

    // ======== BookOfIA ========

    function groupsConcerned(address ia) external view returns (uint16[]);

    function isConcernedGroup(address ia, uint16 group)
        external
        view
        returns (bool);

    function topGroup(address ia)
        external
        view
        returns (
            uint16 groupNum,
            uint256 amount,
            bool isOrgController,
            uint256 netIncreasedAmt,
            uint256 shareRatio
        );

    // function topAmount(address ia) external view returns (uint256);

    // function netIncreasedAmount(address ia) external view returns (uint256);

    function mockResults(address ia, uint16 group)
        external
        view
        returns (
            uint256 selAmt,
            uint256 buyAmt,
            uint256 orgAmt,
            uint256 rstAmt
        );

    function typeOfIA(address ia) external view returns (uint8 output);

    function otherMembers(address ia) external view returns (uint40[]);
}
