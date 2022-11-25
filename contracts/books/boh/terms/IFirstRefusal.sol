// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ITerm.sol";

interface IFirstRefusal is ITerm {
    // ###############
    // ##   Event   ##
    // ###############

    event SetFirstRefusal(bytes32 rule);

    event AddRightholder(uint8 indexed typeOfDeal, uint40 rightholder);

    event RemoveRightholder(uint8 indexed typeOfDeal, uint40 rightholder);

    event DelFirstRefusal(uint8 indexed typeOfDeal);

    // ###############
    // ##   Write   ##
    // ###############

    function setFirstRefusal(bytes32 rule) external;

    function delFirstRefusal(uint8 typeOfDeal) external;

    function addRightholder(uint8 typeOfDeal, uint40 rightholder) external;

    function removeRightholder(uint8 typeOfDeal, uint40 acct) external;

    // ################
    // ##  查询接口  ##
    // ################

    function isSubject(uint8 typeOfDeal) external view returns (bool);

    function ruleOfFR(uint8 typeOfDeal) external view returns (bytes32);

    function isRightholder(uint8 typeOfDeal, uint40 acct)
        external
        view
        returns (bool);

    function rightholders(uint8 typeOfDeal)
        external
        view
        returns (uint40[] memory);
}
