/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfSHA {
    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) external;

    function createDoc(
        uint8 docType,
        uint32 creator,
        uint32 createDate
    ) external returns (address body);

    function removeDoc(address body, uint32 caller) external;

    function circulateDoc(
        address body,
        bytes32 rule,
        uint32 submitter,
        uint32 circulateDate
    ) external;

    function pushToNextState(
        address body,
        uint32 sigDate,
        uint32 caller
    ) external;

    function changePointer(
        address body,
        uint32 caller,
        uint32 sigDate
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function template() external view returns (address);

    function bookName() external view returns (string);

    function isRegistered(address body) external view returns (bool);

    function passedReview(address body) external view returns (bool);

    function isCirculated(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (bytes32[]);

    function getDoc(address sha)
        external
        view
        returns (bytes32 sn, bytes32 docHash);

    function currentState(address body) external view returns (uint8);

    function startDateOf(address body, uint8 state)
        external
        view
        returns (uint32);

    function reviewDeadlineOf(address body) external view returns (uint32);

    function votingDeadlineOf(address body) external view returns (uint32);

    function pointer() external view returns (address);
}
