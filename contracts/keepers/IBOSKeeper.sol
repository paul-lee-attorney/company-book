// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOSKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    // ==== BOS funcs ====

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

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external;

    function updatePaidInDeadline(
        uint32 ssn, 
        uint32 line
    ) external;
}