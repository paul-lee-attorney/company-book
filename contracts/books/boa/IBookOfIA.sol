/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfIA {
    //##################
    //##    event     ##
    //##################

    event CalculateResult(
        address indexed ia,
        uint16 topGroup,
        uint64 topAmt,
        bool isOrgController,
        uint16 shareRatio
    );

    event AddAlongDeal(
        address ia,
        uint16 follower,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    );

    event AcceptAlongDeal(address ia, bytes32 sn);

    //##################
    //##    写接口    ##
    //##################

    // ======== BookOfIA ========

    function circulateIA(address ia, uint40 submitter) external;

    function mockDealOfSell(
        address ia,
        uint40 seller,
        uint64 amount
    ) external;

    function mockDealOfBuy(
        address ia,
        uint16 ssn,
        uint40 buyer,
        uint64 amount
    ) external;

    function calculateMockResult(address ia) external;

    // function proposeIA(
    //     address ia,
    //     uint32 proposeDate,
    //     uint40 caller
    // ) external;

    function addAlongDeal(
        address ia,
        bytes32 rule,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external;

    function acceptAlongDeal(address ia, bytes32 sn) external;

    // ==== DocumentsRepo ====

    function setTemplate(address body) external;

    function createDoc(uint8 docType, uint40 creator)
        external
        returns (address body);

    function removeDoc(address body) external;

    function circulateDoc(
        address body,
        bytes32 rule,
        uint40 submitter
    ) external;

    function pushToNextState(address body, uint40 caller) external;

    //##################
    //##    读接口    ##
    //##################

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
            uint64 amount,
            bool isOrgController,
            uint64 netIncreasedAmt,
            uint16 shareRatio
        );

    function mockResults(address ia, uint16 group)
        external
        view
        returns (
            uint64 selAmt,
            uint64 buyAmt,
            uint64 orgAmt,
            uint64 rstAmt
        );

    function typeOfIA(address ia) external view returns (uint8 output);

    // ==== DocumentsRepo ====

    function template() external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function counterOfDocs() external view returns (uint16);

    function passedReview(address body) external view returns (bool);

    function isCirculated(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (bytes32[]);

    function getDoc(address body)
        external
        view
        returns (bytes32 sn, bytes32 docHash);

    function currentState(address body) external view returns (uint8);

    function startDateOf(address body, uint8 state)
        external
        view
        returns (uint32);

    function reviewDeadlineBNOf(address body) external view returns (uint32);

    function votingDeadlineBNOf(address body) external view returns (uint32);
}
