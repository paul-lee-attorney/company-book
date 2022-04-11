/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface ISigPage {
    //####################
    //##     event      ##
    //####################

    event DocStateRevised(address doc, uint8 state);

    event SetSigDeadline(address doc, uint deadline);

    event SetClosingStartpoint(address doc, uint startpoint);

    event SetClosingDeadline(address doc, uint deadline);

    event AddParty(address doc, address acct);

    event RemoveParty(address doc, address acct);

    event SignDoc(address doc, address acct);

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint deadline) external;

    function setClosingDeadline(uint deadline) external;

    function circulateDoc() external;

    function addPartyToDoc(address acct) external;

    function removePartyFromDoc(address acct) external;

    function signDoc() external;

    // function submitDoc() external;

    function closeDoc(bool flag) external;

    function updateStateOfDoc(uint8 state) external;

    function acceptDoc() external;

    //####################
    //##    查询接口    ##
    //####################

    function isEstablished() external returns (bool);

    function docState() external returns (uint8);

    function sigDeadline() external returns (uint);

    function closingStartpoint() external returns (uint);

    function closingDeadline() external returns (uint);

    function isParty(address acct) external returns (bool);

    function qtyOfParties() external returns (uint8);

    function signedBy(address acct) external returns (bool);

    function sigDate(address acct) external returns (uint);

    function signers() external returns (address[]);

    function qtyOfSigners() external returns (uint);
}
