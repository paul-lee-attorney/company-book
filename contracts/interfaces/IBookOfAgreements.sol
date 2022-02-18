/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../lib/SerialNumFactory.sol";
import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "../interfaces/IAdminSetting.sol";

import "../config/BOSSetting.sol";

interface IBookOfAgreements {
    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address tempAdd, address admin);

    event CreateAgreement(address indexed doc, address creator);

    event RemoveDocument(address body, address admin);

    event SubmitDocument(address body, bytes32 docHash, address admin);

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) external;

    function removeTemplate() external;

    function createAgreement(uint8 docType) external returns (address body);

    function removeAgreement(address body) external;

    function submitAgreement(address body, bytes32 docHash) external;

    //##################
    //##    读接口    ##
    //##################

    function getTemplate() external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function isSubmitted(address body) external view returns (bool);

    function getDocHash(address body) external view returns (bytes32 docHash);

    function getQtyOfDocuments() external view returns (uint256);
}
