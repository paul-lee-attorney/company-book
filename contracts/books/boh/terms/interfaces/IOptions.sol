/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IOptions {
    function counterOfOptions() external view returns (uint16);

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
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
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

    function sn(bytes6 ssn) external view returns (bytes32);

    function isOption(bytes6 ssn) external view returns (bool);

    function isObligor(bytes6 ssn, uint40 acct) external view returns (bool);

    function getObligors(bytes6 ssn) external view returns (uint40[]);

    function isRightholder(bytes6 ssn, uint40 acct)
        external
        view
        returns (bool);

    function rightholder(bytes6 ssn) external view returns (uint40);

    function snList() external returns (bytes32[] list);
}
