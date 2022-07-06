/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

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

    function createSHA(uint8 docType, uint40 caller) external;

    function removeSHA(address body, uint40 caller) external;

    function circulateSHA(address body, uint40 caller) external;

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function effectiveSHA(address body, uint40 caller) external;
}
