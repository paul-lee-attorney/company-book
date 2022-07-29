/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfOptions {
    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        bytes32 indexed sn,
        uint40 rightholder,
        uint40 obligor,
        uint64 parValue,
        uint64 paidPar
    );

    event RegisterOpt(bytes32 indexed sn);

    event AddObligorIntoOpt(bytes32 sn, uint40 obligor);

    event RemoveObligorFromOpt(bytes32 sn, uint40 obligor);

    // event DelOpt(bytes32 indexed sn);

    event CloseOpt(bytes32 indexed sn, string hashKey);

    // event SetOptState(bytes32 indexed sn, uint8 state);

    event ExecOpt(bytes32 indexed sn);

    event RevokeOpt(bytes32 indexed sn);

    event UpdateOracle(uint256 data_1, uint256 data_2);

    event AddFuture(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    );

    event DelFuture(bytes32 indexed sn);

    event AddPledge(bytes32 indexed sn, bytes32 shareNumber, uint64 paidPar);

    event LockOpt(bytes32 indexed sn, bytes32 hashLock);

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        uint8 typeOfOpt,
        uint40 rightholder,
        uint40 obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate,
        uint64 parValue,
        uint64 paidPar
    ) external returns (bytes32 sn);

    function addObligorIntoOpt(bytes6 ssn, uint40 obligor) external;

    function removeObligorFromOpt(bytes6 ssn, uint40 obligor) external;

    function registerOption(address opts) external;

    function updateOracle(uint256 d1, uint256 d2) external;

    function execOption(bytes6 ssn) external;

    function addFuture(
        bytes6 ssn,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external;

    function removeFuture(bytes6 ssn, bytes32 ft) external;

    function requestPledge(
        bytes6 ssn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external;

    function lockOption(bytes6 ssn, bytes32 hashLock) external;

    function closeOption(bytes6 ssn, string hashKey) external;

    function revokeOption(bytes6 ssn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint16);

    function isOption(bytes6 ssn) external view returns (bool);

    function getOption(bytes6 ssn)
        external
        view
        returns (
            bytes32 sn,
            uint40 rightholder,
            uint32 closingDate,
            uint64 parValue,
            uint64 paidPar,
            bytes32 hashLock,
            uint8 state
        );

    function isObligor(bytes6 ssn, uint40 acct) external view returns (bool);

    function obligors(bytes6 ssn) external view returns (uint40[]);

    function stateOfOption(bytes6 ssn) external view returns (uint8);

    function futures(bytes6 ssn) external view returns (bytes32[]);

    function pledges(bytes6 ssn) external view returns (bytes32[]);

    function snList() external view returns (bytes32[]);

    function oracles() external view returns (uint256 d1, uint256 d2);
}
