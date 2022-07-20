/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function createIA(uint8 docType, uint40 caller) external;

    function removeIA(address body, uint40 caller) external;

    function circulateIA(address body, uint40 caller) external;

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function transferTargetShare(address ia, bytes32 sn) external;

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint40 drager,
        bool dragAlong,
        uint40 caller,
        // uint32 sigDate,
        bytes32 sigHash
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint40 caller,
        uint32 execDate,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate,
        uint40 caller
    ) external;

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint32 closingDate,
        uint40 caller
    ) external;

    function closeDeal(
        address ia,
        bytes32 sn,
        string hashKey,
        uint40 caller
    ) external;

    function revokeDeal(
        address ia,
        bytes32 sn,
        string hashKey,
        uint40 caller
    ) external;
}
