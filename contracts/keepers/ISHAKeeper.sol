/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface ISHAKeeper {
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
        uint40 caller,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint40 caller
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusal(
        address ia,
        bytes32 sn,
        uint40 caller,
        bytes32 sigHash
    ) external;
}
