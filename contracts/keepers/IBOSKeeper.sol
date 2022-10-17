// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOSKeeper {
    // ###################
    // ##   Write I/O   ##
    // ###################

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
        uint64 parValue,
        uint64 paidPar
    ) external;

    function updateShareState(uint32 ssn, uint8 state) external;

    function setMaxQtyOfMembers(uint8 max) external;
}
