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
        address creditor,
        address debtor,
        uint256 guaranteedAmt
    ) external;

    function updatePledge(
        bytes32 sn,
        address creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external;

    function delPledge(bytes32 sn) external;
}
