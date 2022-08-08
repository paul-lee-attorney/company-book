/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfSHA {
    //##############
    //##  Event   ##
    //##############

    event ChangePointer(address indexed pointer, address indexed body);

    //##################
    //##    写接口    ##
    //##################

    function changePointer(address body, uint40 caller) external;

    // ==== DocumentsRepo ====

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

    function pointer() external view returns (address);

    // ==== DocumentsRepo ====

    function template(uint8 typeOfDoc) external view returns (address);

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
