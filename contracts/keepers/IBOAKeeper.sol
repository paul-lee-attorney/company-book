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

    function removeIA(address ia, uint40 caller) external;

    function circulateIA(address ia, uint40 caller) external;

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
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

    function transferTargetShare(address ia, bytes32 sn) external;

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        string hashKey
    ) external;
}
