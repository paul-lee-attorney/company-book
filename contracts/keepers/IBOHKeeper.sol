/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOHKeeper {
    // ################
    // ##   Events   ##
    // ################

    event AddTemplate(uint8 title, address add);

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(
        uint8 title,
        address add,
        uint40 caller
    ) external;

    function createSHA(uint8 docType, address caller) external;

    function removeSHA(address sha, uint40 caller) external;

    function circulateSHA(address sha, address callerAddr) external;

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function effectiveSHA(address sha, uint40 caller) external;
}
