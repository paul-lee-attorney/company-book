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

    function removePartyFromDoc(address acct) external;

    function finalizeDoc() external;

    function signDoc(
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function acceptDoc(uint32 sigDate, bytes32 sigHash) external;

    function addBlank(uint32 acct, uint16 sn) external;

    function signDeal(
        uint16 ssn,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function backToFinalized(uint32 reviewDeadline) external;

    //####################
    //##    查询接口    ##
    //####################

    function established() external returns (bool);

    function sigDeadline() external returns (uint32);

    function closingDeadline() external returns (uint32);

    function isParty(address acct) external returns (bool);

    function isSigner(address acct) external returns (bool);

    function isInitSigner(uint32 acct) external view returns (bool);

    function parties() external returns (uint32[]);

    function qtyOfParties() external returns (uint8);

    function qtyOfBlankForParty(uint32 acct) external view returns (uint16);

    function qtyOfSigForParty(uint32 acct) external view returns (uint16);

    function sigDateOfDeal(uint32 acct, uint16 sn)
        external
        view
        returns (uint32);

    function sigHashOfDeal(uint32 acct, uint16 sn)
        external
        view
        returns (bytes32);

    function sigDateOfDoc(uint32 acct) external view returns (uint32);

    function sigHashOfDoc(uint32 acct) external view returns (bytes32);

    function dealSigVerify(
        uint32 acct,
        uint16 sn,
        string src
    ) external view returns (bool);

    function partyDulySigned(uint32 acct) external view returns (bool);
}
