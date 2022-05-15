/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOOKeeper {
    // #################
    // ##  BOOKeeper  ##
    // #################

    function termsTemplate(uint256 index) external returns (address);

    function createOption(
        uint8 typeOfOpt,
        address rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function joinOptionAsObligor(bytes32 sn) external;

    function releaseObligorFromOption(bytes32 sn, address obligor) external;

    function execOption(bytes32 sn, uint32 exerciseDate) external;

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external;

    function removeFuture(bytes32 sn, bytes32 ft) external;

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external;

    function lockOption(bytes32 sn, bytes32 hashLock) external;

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate
    ) external;

    function revokeOption(bytes32 sn, uint32 revokeDate) external;

    function releasePledges(bytes32 sn) external;
}
