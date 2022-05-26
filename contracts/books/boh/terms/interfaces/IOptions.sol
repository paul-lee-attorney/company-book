/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IOptions {
    function isOption(uint16 ssn) external view returns (bool);

    function counterOfOptions() external view returns (uint16);

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        uint8 typeOfOpt,
        uint32 rightholder,
        uint32 obligor,
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

    function addObligorIntoOpt(uint16 sequence, uint32 obligor) external;

    function removeObligorFromOpt(uint16 sequence, uint32 obligor) external;

    function delOption(uint16 sequence) external;

    // ################
    // ##  查询接口  ##
    // ################

    function sn(uint16 sequence) external view returns (bytes32);

    function isObligor(uint16 sequence, uint32 acct)
        external
        view
        returns (bool);

    function getObligors(uint16 sequence) external view returns (uint32[]);

    function isRightholder(uint16 sequence, uint32 acct)
        external
        view
        returns (bool);

    function rightholder(uint16 sequence) external view returns (uint32);

    function snList() external returns (bytes32[] list);
}