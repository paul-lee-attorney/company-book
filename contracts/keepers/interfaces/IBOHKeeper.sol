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

    function createSHA(
        uint8 docType,
        uint32 caller,
        uint32 createDate
    ) external returns (address body);

    function removeSHA(address body, uint32 caller) external;

    function circulateSHA(
        address body,
        uint32 caller,
        uint32 submitDate
    ) external;

    function signSHA(
        address sha,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function effectiveSHA(address body, uint32 caller) external;
}
