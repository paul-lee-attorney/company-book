/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfDocuments {
    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address indexed self, address temp);

    event SetBookSetting(address indexed self, address book);

    event CreateDoc(
        address indexed self,
        address indexed doc,
        bytes32 indexed sn
    );

    event RemoveDoc(address indexed self, bytes32 indexed sn, address body);

    event SubmitDoc(address indexed self, bytes32 indexed sn, address body);

    event SetPointer(
        address indexed self,
        bytes32 indexed pointer,
        address body
    );

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) external;

    // function setBookSetting(address book) external;

    function createDoc(uint8 docType) external returns (address body);

    function removeDoc(address body) external;

    function submitDoc(address body, bytes32 docHash) external;

    function setPointer(address body) external;

    //##################
    //##    读接口    ##
    //##################

    function getTemplate() external view returns (address);

    // function getBookSetting() external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function isSubmitted(address body) external view returns (bool);

    function getQtyOfDocuments() external view returns (uint256);

    function getDocs() external view returns (bytes32[]);

    function getDoc(bytes32 sn)
        external
        view
        returns (
            address body,
            bytes32 docHash,
            uint8 state
        );

    function getSN(address body) external view returns (bytes32);

    function getPointer() external view returns (bytes32);

    function getTheOne() external view returns (address);
}
