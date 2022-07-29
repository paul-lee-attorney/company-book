/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IFirstRefusalToolKits {
    //##################
    //##    Event     ##
    //##################

    // ======== FRDeal ========

    event UpdateFRDeal(bytes32 indexed sn, uint64 parValue, uint64 paidPar);

    event AcceptFR(bytes32 indexed sn, uint40 sender);

    event CreateFRDeal(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint32 unitPrice,
        uint64 parValue,
        uint64 paidPar,
        uint32 closingDate
    );

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 ssn,
        uint40 acct,
        bytes32 sigHash
    ) external returns (bytes32);

    function acceptFR(
        uint16 ssn,
        uint40 acct,
        bytes32 sigHash
    ) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    // ======== FirstRefusal ========

    function counterOfFR(uint16 ssn) external view returns (uint16);

    function sumOfWeight(uint16 ssn) external view returns (uint64);

    function isTargetDeal(uint16 ssn) external view returns (bool);

    function frDeals(uint16 ssn) external view returns (uint16[]);
}
