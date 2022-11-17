// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IROMKeeper {

    // ############
    // ##  ROM   ##
    // ############

    function setVoteBase(bool onPar) external;

    function setMaxQtyOfMembers(uint8 max) external;

    function setAmtBase(bool onPar) external;
}
