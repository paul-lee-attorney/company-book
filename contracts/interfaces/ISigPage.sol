/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface ISigPage {
    //####################
    //##     event      ##
    //####################

    event DocStateRevised(address doc, uint8 state);

    event SetSigDeadline(address doc, uint256 deadline);

    event SetClosingStartpoint(address doc, uint256 startpoint);

    event SetClosingDeadline(address doc, uint256 deadline);

    event AddParty(address doc, address acct);

    event RemoveParty(address doc, address acct);

    event SignDoc(address doc, address acct);

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint256 deadline) public;

    function setClosingDeadline(uint256 deadline) public;

    function circulateDoc() public;

    function addPartyToDoc(address acct) public;

    function removePartyFromDoc(address acct) public;

    function signDoc() public;

    function submitDoc() public;

    function closeDoc(bool flag) public;

    function acceptDoc() public;

    //####################
    //##    查询接口    ##
    //####################

    function isEstablished() public returns (bool);

    function getDocState() public returns (uint8);

    function getSigDeadline() public returns (uint256);

    function getClosingStartpoint() public returns (uint256);

    function getClosingDeadline() public returns (uint256);

    function isParty(address acct) public returns (bool);

    function getQtyOfParties() public returns (uint8);

    function isSignedBy(address acct) public returns (bool);

    function getSigDate(address acct) public returns (uint256);

    function getSigners() public returns (address[]);

    function getQtyOfSigners() public returns (uint256);
}
