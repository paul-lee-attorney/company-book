/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfOptions {
    function futures(bytes32 sn) external returns (bytes32[]);

    function isOption(bytes32 sn) external returns (bool);

    function counterOfOptions() external returns (uint16);

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        uint8 typeOfOpt,
        address rightholder,
        address obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 price,
        uint256 parValue
    ) external;

    function pushToFuture(
        bytes32 shareNumber,
        address obligor,
        uint32 exerciseDate,
        uint32 closingDate,
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
            uint32 closingDate,
            uint256 parValue,
            bytes32 hashLock,
            uint8 state
        );

    function stateOfOption(bytes32 sn) external view returns (uint8);

    function parseSN(bytes32 sn)
        external
        pure
        returns (
            uint8 typeOfOpt,
            address obligor,
            uint32 triggerDate,
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
        uint32 exerciseDate,
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
