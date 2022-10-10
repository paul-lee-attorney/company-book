/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IOptions {
    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        bytes32 indexed sn,
        uint64 parValue,
        uint64 paidPar,
        uint40 rightholder,
        uint40 obligor
    );

    event AddObligorIntoOpt(bytes32 sn, uint40 obligor);

    event RemoveObligorFromOpt(bytes32 sn, uint40 obligor);

    event DelOpt(bytes32 indexed sn);

    event AddConditions(bytes32 indexed sn);

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
    ) external;

    function addConditions(
        uint32 ssn,
        uint8 logicOperator,
        uint8 compareOperator_1,
        uint32 para_1,
        uint8 compareOperator_2,
        uint32 para_2
    ) external;

    function addObligorIntoOpt(uint32 ssn, uint40 obligor) external;

    function removeObligorFromOpt(uint32 ssn, uint40 obligor) external;

    function delOption(uint32 ssn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function sn(uint32 ssn) external view returns (bytes32);

    function isOption(uint32 ssn) external view returns (bool);

    function isObligor(uint32 ssn, uint40 acct) external view returns (bool);

    function values(uint32 ssn)
        external
        view
        returns (uint64 parValue, uint64 paidPar);

    function obligors(uint32 ssn) external view returns (uint40[]);

    function isRightholder(uint32 ssn, uint40 acct)
        external
        view
        returns (bool);

    function rightholder(uint32 ssn) external view returns (uint40);

    function snList() external view returns (bytes32[]);
}
