// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

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

    event RegisterOpt(bytes32 indexed sn, uint64 parValue, uint64 paidPar);

    event AddObligorIntoOpt(bytes32 sn, uint40 obligor);

    event RemoveObligorFromOpt(bytes32 sn, uint40 obligor);

    event CloseOpt(bytes32 indexed sn, string hashKey);

    event ExecOpt(bytes32 indexed sn);

    event RevokeOpt(bytes32 indexed sn);

    event UpdateOracle(uint32 seq, uint32 data_1, uint32 data_2);

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

    function addObligorIntoOpt(uint32 seq, uint40 obligor) external;

    function removeObligorFromOpt(uint32 seq, uint40 obligor) external;

    function registerOption(address opts) external;

    function updateOracle(
        uint32 ssn,
        uint32 d1,
        uint32 d2
    ) external;

    function execOption(uint32 ssn) external;

    function addFuture(
        uint32 ssn,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external;

    function removeFuture(uint32 ssn, bytes32 ft) external;

    function requestPledge(
        uint32 ssn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external;

    function lockOption(uint32 ssn, bytes32 hashLock) external;

    function closeOption(uint32 ssn, string memory hashKey) external;

    function revokeOption(uint32 ssn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function isOption(uint32 seq) external view returns (bool);

    function getOption(uint32 seq)
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

    function isObligor(uint32 seq, uint40 acct) external view returns (bool);

    function obligors(uint32 seq) external view returns (uint40[] memory);

    function stateOfOption(uint32 seq) external view returns (uint8);

    function futures(uint32 seq) external view returns (bytes32[] memory);

    function pledges(uint32 seq) external view returns (bytes32[] memory);

    function snList() external view returns (bytes32[] memory);

    function oracle(uint32 seq) external view returns (uint32 d1, uint32 d2);
}
