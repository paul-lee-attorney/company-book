/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function createIA(uint8 docType) external;

    function removeIA(address body) external;

    function submitIA(address body, bytes32 docHash) external;

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external;

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external;

    function acceptAlongDeal(
        address ia,
        address drager,
        bytes32 sn
    ) external;

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 execDate
    ) external;

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate
    ) external;

    function pushToCoffer(
        bytes32 sn,
        address ia,
        bytes32 hashLock,
        uint256 closingDate
    ) external;

    function closeDeal(
        bytes32 sn,
        address ia,
        uint32 closingDate,
        string hashKey
    ) external;

    function revokeDeal(
        bytes32 sn,
        address ia,
        string hashKey
    ) external;
}
