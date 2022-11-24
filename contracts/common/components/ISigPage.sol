// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface ISigPage {
    //####################
    //##     event      ##
    //####################

    event DocFinalized();

    event DocEstablished();

    event SetSigDeadline(uint32 deadline);

    event SetClosingDeadline(uint32 deadline);

    event AddParty(uint40 indexed acct);

    event AddBlank(uint40 indexed acct, uint16 indexed sn);

    event RemoveBlank(uint40 indexed acct, uint16 indexed sn);

    event SignDeal(uint40 indexed acct, uint16 indexed sn, bytes32 sigHash);

    // event SignDoc(uint40 acct, bytes32 sigHash);

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint32 deadline) external;

    function setClosingDeadline(uint32 deadline) external;

    function signDoc(uint40 caller, bytes32 sigHash) external;

    function acceptDoc(bytes32 sigHash, uint40 caller) external;

    function addBlank(uint40 acct, uint16 ssn) external;

    function removeBlank(uint40 acct, uint16 ssn) external;

    function addParty(uint40 acct) external;

    function signDeal(
        uint16 ssn,
        uint40 caller,
        bytes32 sigHash
    ) external;

    //####################
    //##    查询接口    ##
    //####################

    function established() external view returns (bool);

    function sigDeadline() external view returns (uint32);

    function closingDeadline() external view returns (uint32);

    function isParty(uint40 acct) external view returns (bool);

    function isInitSigner(uint40 acct) external view returns (bool);

    function partiesOfDoc() external view returns (uint40[] memory);

    function qtyOfParties() external view returns (uint256);

    function sigCounter() external view returns (uint16);

    function sigOfDeal(uint40 acct, uint16 ssn)
        external view
        returns (
            uint64 blocknumber,
            uint32 sigDate,
            bytes32 sigHash
        );

    function sigDateOfDoc(uint40 acct) external view returns (uint32);

    function sigHashOfDoc(uint40 acct) external view returns (bytes32);

    function dealSigVerify(
        uint40 acct,
        uint16 ssn,
        string memory src
    ) external view returns (bool);
}
