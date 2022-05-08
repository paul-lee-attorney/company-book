/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfAgreements {
    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) external;

    function createDoc(uint8 docType) external returns (address body);

    function removeDoc(address body) external;

    function submitDoc(address body, bytes32 docHash) external;

    function submitIA(
        address ia,
        uint32 submitDate,
        bytes32 docHash,
        address submitter
    ) external;

    function addAlongDeal(
        address ia,
        bytes32 rule,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function acceptAlongDeal(
        address ia,
        address drager,
        bytes32 sn
    ) external;

    function updateStateOfDoc(address body, uint8 newState) external;

    // function setPointer(address body) external;

    //##################
    //##    读接口    ##
    //##################

    function bookName() external view returns (string);

    function template() external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function counterOfDocs() external view returns (uint16);

    function isSubmitted(address body) external view returns (bool);

    function qtyOfDocuments() external view returns (uint256);

    function docsList() external view returns (bytes32[]);

    function getDoc(address body)
        external
        view
        returns (
            bytes32 sn,
            uint32 submitDate,
            bytes32 docHash
        );

    function stateOfDoc(address body) external view returns (uint8);

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
}
