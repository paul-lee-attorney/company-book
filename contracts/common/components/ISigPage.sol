/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface ISigPage {
    //####################
    //##     event      ##
    //####################

    event DocFinalized();

    event BackToFinalized();

    event DocEstablished();

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(uint40 acct);

    event RemoveParty(uint40 acct);

    event AddBlank(uint40 acct, uint16 sn);

    event SignDeal(uint40 acct, uint16 sn, bytes32 sigHash);

    event SignDoc(uint40 acct, bytes32 sigHash);

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint256 deadline) external;

    function setClosingDeadline(uint256 deadline) external;

    function removePartyFromDoc(address acct) external;

    function finalizeDoc() external;

    function signDoc(uint40 caller, bytes32 sigHash) external;

    function acceptDoc(bytes32 sigHash) external;

    function addBlank(uint40 acct, uint16 sn) external;

    function signDeal(
        uint16 ssn,
        uint40 caller,
        bytes32 sigHash
    ) external;

    //####################
    //##    查询接口    ##
    //####################

    function established() external returns (bool);

    function sigDeadline() external returns (uint32);

    function closingDeadline() external returns (uint32);

    function isParty(address acct) external returns (bool);

    function isSigner(address acct) external returns (bool);

    function isInitSigner(uint40 acct) external view returns (bool);

    function parties() external view returns (uint40[]);

    function qtyOfParties() external view returns (uint256);

    function qtyOfBlankForParty(uint40 acct) external view returns (uint16);

    function qtyOfSigForParty(uint40 acct) external view returns (uint16);

    function sigDateOfDeal(uint40 acct, uint16 sn)
        external
        view
        returns (uint32);

    function sigHashOfDeal(uint40 acct, uint16 sn)
        external
        view
        returns (bytes32);

    function sigDateOfDoc(uint40 acct) external view returns (uint32);

    function sigHashOfDoc(uint40 acct) external view returns (bytes32);

    function dealSigVerify(
        uint40 acct,
        uint16 sn,
        string src
    ) external view returns (bool);

    function partyDulySigned(uint40 acct) external view returns (bool);
}
