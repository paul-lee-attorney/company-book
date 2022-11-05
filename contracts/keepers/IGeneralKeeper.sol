// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IGeneralKeeper {

    // ###############
    // ##   Event   ##
    // ###############

    event SetBOAKeeper(address keeper);

    event SetBODKeeper(address keeper);

    event SetSHAKeeper(address keeper);

    event SetBOHKeeper(address keeper);

    event SetBOMKeeper(address keeper);

    event SetBOOKeeper(address keeper);

    event SetBOPKeeper(address keeper);

    event SetBOSKeeper(address keeper);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function isKeeper(address caller) external returns(bool flag);
}