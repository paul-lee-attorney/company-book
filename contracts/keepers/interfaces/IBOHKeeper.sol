/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOHKeeper {
    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(
        uint8 title,
        address add,
        uint32 caller
    ) external;

    function createSHA(uint8 docType, uint32 caller)
        external
        returns (address body);

    function removeSHA(address body, uint32 caller) external;

    function submitSHA(
        address body,
        bytes32 docHash,
        uint32 caller
    ) external;

    function effectiveSHA(address body, uint32 caller) external;
}
