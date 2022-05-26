/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOOKeeper {
    // #################
    // ##  BOOKeeper  ##
    // #################

    function termsTemplate(uint256 index, uint32 caller)
        external
        returns (address);

    function createOption(
        uint8 typeOfOpt,
        uint32 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller
    ) external;

    function joinOptionAsObligor(bytes32 sn, uint32 caller) external;

    function releaseObligorFromOption(
        bytes32 sn,
        uint32 obligor,
        uint32 caller
    ) external;

    function execOption(
        bytes32 sn,
        uint32 exerciseDate,
        uint32 caller
    ) external;

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar,
        uint32 caller
    ) external;

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint32 caller
    ) external;

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar,
        uint32 caller
    ) external;

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint32 caller
    ) external;

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate,
        uint32 caller
    ) external;

    function revokeOption(
        bytes32 sn,
        uint32 revokeDate,
        uint32 caller
    ) external;

    function releasePledges(bytes32 sn, uint32 caller) external;
}
