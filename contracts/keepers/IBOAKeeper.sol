// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function createIA(uint8 docType, uint40 caller) external;

    function removeIA(address ia, uint40 caller) external;

    function circulateIA(address ia, uint40 caller) external;

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external;

    function setMaxQtyOfMembers(uint8 max) external;

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external;

    function requestPaidInCapital(
        uint32 ssn,
        string memory hashKey,
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
        string memory hashKey,
        uint40 caller
    ) external;

    function transferTargetShare(address ia, bytes32 sn) external;

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        string memory hashKey
    ) external;
}
