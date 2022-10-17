// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IOptions {
    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        uint40 indexed ssn,
        uint64 parValue,
        uint64 paidPar,
        uint40 rightholder,
        uint40 obligor
    );

    event AddObligorIntoOpt(uint40 ssn, uint40 obligor);

    event RemoveObligorFromOpt(uint40 ssn, uint40 obligor);

    event DelOpt(uint40 ssn);

    event AddConditions(uint40 ssn, bytes32 sn);

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        uint8 typeOfOpt,
        uint40 _rightholder,
        uint40 obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate,
        uint64 paid,
        uint64 par
    ) external;

    function addConditions(
        uint40 ssn,
        uint8 logicOperator,
        uint8 compareOperator_1,
        uint32 para_1,
        uint8 compareOperator_2,
        uint32 para_2
    ) external;

    function addObligorIntoOpt(uint40 ssn, uint40 obligor) external;

    function removeObligorFromOpt(uint40 ssn, uint40 obligor) external;

    function delOption(uint40 ssn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOpts() external view returns (uint40);

    function isOpt(uint40 ssn) external view returns (bool); 

    function qtyOfOpts() external view returns(uint40);

    function isObligor(uint40 ssn, uint40 acct) external view returns (bool);

    function getOpt(uint40 ssn)
        external
        view
        returns (
            bytes32 sn,
            uint64 paid, 
            uint64 par,
            uint40 rightholder
        );

    function obligors(uint40 ssn) external view returns (uint40[] memory);

    function isRightholder(uint40 ssn, uint40 acct) external view returns (bool);

    function ssnList() external view returns (uint40[] memory);
}
