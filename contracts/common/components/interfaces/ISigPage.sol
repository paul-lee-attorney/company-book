/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface ISigPage {
    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint256 deadline) external;

    function setClosingDeadline(uint256 deadline) external;

    function circulateDoc() external;

    function addPartyToDoc(address acct) external;

    function removePartyFromDoc(address acct) external;

    function signDoc() external;

    // function submitDoc() external;

    function closeDoc(bool flag) external;

    function updateStateOfDoc(uint8 state) external;

    function addSigOfParty(address acct, uint32 sigDate) external;

    function removeSigOfParty(address acct) external;

    function acceptDoc() external;

    //####################
    //##    查询接口    ##
    //####################

    function isEstablished() external returns (bool);

    function docState() external returns (uint8);

    function sigDeadline() external returns (uint256);

    function closingStartpoint() external returns (uint256);

    function closingDeadline() external returns (uint256);

    function isParty(address acct) external returns (bool);

    function qtyOfParties() external returns (uint8);

    function signedBy(address acct) external returns (bool);

    function sigDate(address acct) external returns (uint256);

    function signers() external returns (uint32[]);

    function qtyOfSigners() external returns (uint256);
}
