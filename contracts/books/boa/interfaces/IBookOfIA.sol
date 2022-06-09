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

    function createDoc(uint8 docType) external returns (address body);

    function removeDoc(address body) external;

    // ======== BookOfIA ========

    function submitIA(
        address ia,
        uint32 submitter,
        uint32 submitDate,
        bytes32 docHash
    ) external;

    function rejectDoc(
        address body,
        uint32 sigDate,
        uint32 caller
    ) external;

    function addAlongDeal(
        address ia,
        bytes32 rule,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 execDate
    ) external;

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint32 drager,
        bool dragAlong
    ) external;

    function proposeDoc(
        address body,
        uint32 sigDate,
        uint32 caller
    ) external;

    function pushToNextState(
        address body,
        uint32 sigDate,
        uint32 caller
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function passedReview(address ia) external returns (bool);

    function reviewDeadlineOf(address body) external view returns (uint32);

    function bookName() external view returns (string);

    function template() external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function counterOfDocs() external view returns (uint16);

    function isSubmitted(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (bytes32[]);

    function getDoc(address body)
        external
        view
        returns (bytes32 sn, bytes32 docHash);

    function currentState(address body) external view returns (uint8);

    function startDateOf(address body) external view returns (uint32);

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

    function topAmount(address ia) external view returns (uint256);

    function netIncreasedAmount(address ia) external view returns (uint256);

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

    function otherMembers(address ia) external view returns (uint32[]);
}
