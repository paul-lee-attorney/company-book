// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOHKeeper {

    // ############
    // ##  ROM   ##
    // ############

    function setVoteBase(bool onPar) external;

    function setMaxQtyOfMembers(uint8 max) external;

    function setAmtBase(bool onPar) external;

    // ############
    // ##  SHA   ##
    // ############

    function setTempOfSHA(address temp, uint8 typeOfDoc, uint40 caller) external;

    function setTermTemplate(
        uint8 title,
        address body,
        uint40 caller
    ) external;

    function createSHA(uint8 docType, uint40 caller) external;

    function removeSHA(address sha, uint40 caller) external;

    function circulateSHA(address sha, uint40 caller) external;

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function effectiveSHA(address sha, uint40 caller) external;

    function acceptSHA(bytes32 sigHash, uint40 caller) external;
}
