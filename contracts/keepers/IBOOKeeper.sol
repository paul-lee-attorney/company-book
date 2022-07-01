/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOOKeeper {
    // #################
    // ##  BOOKeeper  ##
    // #################

    function termsTemplate(uint256 index, uint40 caller)
        external
        returns (address);

    function createOption(
        uint8 typeOfOpt,
        uint40 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar,
        uint40 caller
    ) external;

    function joinOptionAsObligor(bytes32 sn, uint40 caller) external;

    function releaseObligorFromOption(
        bytes32 sn,
        uint40 obligor,
        uint40 caller
    ) external;

    function execOption(bytes32 sn, uint40 caller) external;

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar,
        uint40 caller
    ) external;

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint40 caller
    ) external;

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar,
        uint40 caller
    ) external;

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint40 caller
    ) external;

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint40 caller
    ) external;

    function revokeOption(bytes32 sn, uint40 caller) external;

    function releasePledges(bytes32 sn, uint40 caller) external;
}
