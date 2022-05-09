/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfOptions {
    function futures(bytes6 ssn) external view returns (bytes32[]);

    function pledges(bytes6 ssn) external view returns (bytes32[]);

    function isOption(bytes6 ssn) external view returns (bool);

    function snList() external view returns (bytes32[]);

    function counterOfOptions() external view returns (bytes32[]);

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
        uint256 parValue,
        uint256 paidPar
    ) external returns (bytes32 sn);

    function updateOption(
        bytes6 ssn,
        address rightholder,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function addObligorIntoOpt(bytes6 ssn, address obligor) external;

    function removeObligorFromOpt(bytes6 ssn, address obligor) external;

    function registerOption(address opts) external;

    function setState(bytes32 sn, uint8 state) external;

    function execOption(bytes32 sn, uint32 exerciseDate) external;

    function addFuture(
        bytes6 ssn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function removeFuture(bytes6 ssn, bytes32 ft) external;

    function requestPledge(
        bytes6 ssn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external;

    function lockOption(bytes6 ssn, bytes32 hashLock) external;

    function closeOption(
        bytes6 ssn,
        string hashKey,
        uint32 closingDate
    ) external;

    function revokeOption(bytes6 ssn, uint32 revokeDate) external;

    // ################
    // ##  查询接口  ##
    // ################

    function getOption(bytes6 ssn)
        external
        view
        returns (
            bytes32 sn,
            address rightholder,
            uint32 closingDate,
            uint256 parValue,
            uint256 paidPar,
            bytes32 hashLock,
            uint8 state
        );

    function isObligor(bytes6 ssn, address acct) external view returns (bool);

    function stateOfOption(bytes6 ssn) external view returns (uint8);
}
