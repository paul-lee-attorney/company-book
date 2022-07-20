/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IOptions {
    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(bytes32 indexed sn, uint40 rightholder, uint40 obligor);

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
        uint16 sequence,
        uint8 logicOperator,
        uint8 compareOperator_1,
        uint32 para_1,
        uint8 compareOperator_2,
        uint32 para_2
    ) external;

    function addObligorIntoOpt(bytes6 ssn, uint40 obligor) external;

    function removeObligorFromOpt(bytes6 ssn, uint40 obligor) external;

    function delOption(bytes6 ssn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint16);

    function sn(bytes6 ssn) external view returns (bytes32);

    function isOption(bytes6 ssn) external view returns (bool);

    function isObligor(bytes6 ssn, uint40 acct) external view returns (bool);

    function getObligors(bytes6 ssn) external view returns (uint40[]);

    function isRightholder(bytes6 ssn, uint40 acct)
        external
        view
        returns (bool);

    function rightholder(bytes6 ssn) external view returns (uint40);

    function snList() external view returns (bytes32[] list);
}
