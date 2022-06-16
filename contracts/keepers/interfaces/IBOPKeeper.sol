/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOPKeeper {
    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        uint40 creditor,
        uint40 debtor,
        uint256 guaranteedAmt,
        uint40 caller
    ) external;

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt,
        uint40 caller
    ) external;

    function delPledge(bytes32 sn, uint40 caller) external;
}
