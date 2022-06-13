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
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 sigDate,
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

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 sigDate
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 caller,
        uint32 acceptDate,
        bytes32 sigHash
    ) external;
}
