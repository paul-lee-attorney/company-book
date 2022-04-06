/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfOptions {
    function futures(bytes32 sn) external returns (bytes32[]);

    function isOption(bytes32 sn) external returns (bool);

    function counterOfOpts() external returns (uint16);

    // ################
    // ##   写接口   ##
    // ################

    function createSN(
        uint8 typeOfOpt, //0-call option; 1-put option
        address obligor,
        uint256 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 price
    ) private pure returns (bytes32 sn);

    function createOption(
        uint8 typeOfOpt,
        address rightholder,
        address obligor,
        uint256 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 price,
        uint256 parValue
    ) external;

    function pushToFuture(
        bytes32 shareNumber,
        address obligor,
        uint256 exerciseDate,
        uint256 closingDate,
        uint256 price,
        uint256 parValue
    ) external;

    function setState(bytes32 sn, uint8 state) external;

    // ################
    // ##  查询接口  ##
    // ################

    function getOption(bytes32 sn)
        external
        view
        returns (
            address rightholder,
            uint256 closingDate,
            uint256 parValue,
            bytes32 hashLock,
            uint8 state
        );

    function parseSN(bytes32 sn)
        public
        pure
        returns (
            uint8 typeOfOpt,
            address obligor,
            uint256 triggerDate,
            uint8 exerciseDays,
            uint8 closingDays,
            uint256 price
        );

    function getSNList() external view returns (bytes32[] list);

    // ################
    // ##  Term接口  ##
    // ################

    function execOption(
        bytes32 sn,
        uint256 exerciseDate,
        bytes32 hashLock
    ) external;

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue
    ) external;

    function removeFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue
    ) external;

    function closeOption(bytes32 sn, bytes32 hashKey) external;

    function revokeOption(bytes32 sn) external;
}
