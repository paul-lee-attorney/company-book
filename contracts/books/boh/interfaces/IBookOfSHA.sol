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

    function createDoc(uint8 docType) external returns (address body);

    function removeDoc(address body) external;

    function submitDoc(
        address body,
        uint32 submitter,
        uint32 submitDate,
        bytes32 docHash
    ) external;

    function updateStateOfDoc(address body, uint8 newState) external;

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

    function isRegisteredTerm(address term) external view returns (bool);

    function isCirculated(address body) external view returns (bool);

    function qtyOfDocuments() external view returns (uint256);

    function docs() external view returns (bytes32[]);

    function getDoc(bytes32 sn)
        external
        view
        returns (
            address body,
            bytes32 docHash,
            uint8 state
        );

    function currentState(address body) external view returns (uint8);

    function bodyToSN(address body) external view returns (bytes32);

    function pointer() external view returns (address);
}
