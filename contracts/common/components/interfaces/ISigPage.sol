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

    function addPartyToDoc(address acct) external;

    function removePartyFromDoc(address acct) external;

    function circulateDoc() external;

    function signDoc(uint32 _sigDate, bytes32 _sigHash) external;

    // function updateStateOfDoc(uint8 state) external;

    function addSigOfParty(
        address acct,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    // function removeSigOfParty(address acct) external;

    function acceptDoc(uint32 sigDate, bytes32 sigHash) external;

    function backToDraft() external;

    //####################
    //##    查询接口    ##
    //####################

    function established() external returns (bool);

    // function docState() external returns (uint8);

    function sigDeadline() external returns (uint32);

    // function closingStartpoint() external returns (uint32);

    function closingDeadline() external returns (uint32);

    function isParty(address acct) external returns (bool);

    function parties() external returns (uint32[]);

    function qtyOfParties() external returns (uint8);

    function counterOfParty(uint32 acct) external view returns (uint16);

    function counterOfParties() external view returns (uint16);

    function isSigner(address acct) external returns (bool);

    function signers() external returns (uint32[]);

    function qtyOfSigners() external returns (uint256);

    function counterOfSigner(uint32 acct) external view returns (uint16);

    function counterOfSigners() external view returns (uint16);

    function sigDate(address acct) external returns (uint32);

    function sigHash(address acct) external returns (bytes32);

    function sigVerify(address acct, string src) external returns (bool);
}
