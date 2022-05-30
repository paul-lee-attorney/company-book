/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function createIA(uint8 docType, uint32 caller) external;

    function removeIA(address body, uint32 caller) external;

    function submitIA(
        address body,
        uint32 submitDate,
        bytes32 docHash,
        uint32 caller
    ) external;

    // ======== TagAlong ========

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 execDate,
        bytes32 sigHash
    ) external;

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 execDate,
        bytes32 sigHash
    ) external;

    function acceptTagAlong(
        address ia,
        address drager,
        bytes32 sn,
        uint32 caller,
        uint32 sigDate
    ) external;

    function acceptDragAlong(
        bytes32 snOfOpt,
        bytes32 shareNumber,
        uint32 caller,
        uint32 sigDate
    ) external;

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
        uint32 caller
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
