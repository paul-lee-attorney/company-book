/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

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
        string hashKey,
        uint40 caller
    ) external;

    function decreaseCapital(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external;

    function updateShareState(uint32 ssn, uint8 state) external;

    function setMaxQtyOfMembers(uint16 max) external;
}
