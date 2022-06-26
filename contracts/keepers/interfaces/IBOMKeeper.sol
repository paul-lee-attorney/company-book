/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOMKeeper {
    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(
        address ia,
        uint32 proposeDate,
        uint40 caller
    ) external;

    function castVote(
        address ia,
        uint8 attitude,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function againstMotion(
        address ia,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function voteCounting(address ia, uint40 caller) external;

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        address againstVoter,
        uint40 caller
    ) external;
}
