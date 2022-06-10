/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function createIA(
        uint8 docType,
        uint32 caller,
        uint32 createDate
    ) external;

    function removeIA(
        address body,
        uint32 caller,
        uint32 sigDate
    ) external;

    function circulateIA(
        address body,
        uint32 caller,
        uint32 submitDate
    ) external;

    function signIA(
        address ia,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 execDate,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint32 drager,
        bool dragAlong,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 execDate,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate,
        uint32 caller
    ) external;

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint256 closingDate,
        uint32 caller,
        uint32 sigDate
    ) external;

    function closeDeal(
        address ia,
        bytes32 sn,
        uint32 closingDate,
        string hashKey,
        uint32 caller
    ) external;

    function revokeDeal(
        address ia,
        bytes32 sn,
        string hashKey,
        uint32 caller
    ) external;
}
