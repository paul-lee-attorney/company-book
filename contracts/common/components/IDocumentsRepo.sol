// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IDocumentsRepo {
    // //##############
    // //##  Event   ##
    // //##############

    // event SetTemplate(address temp, uint8 typeOfDoc);

    // event UpdateStateOfDoc(bytes32 indexed sn, uint8 state, uint40 caller);

    // event RemoveDoc(bytes32 indexed sn);

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body, uint8 typeOfDoc) external;

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

    function template(uint8 typeOfDoc) external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function counterOfDocs() external view returns (uint32);

    function passedReview(address body) external view returns (bool);

    function isCirculated(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (bytes32[] memory);

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
