/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

interface IBOMKeeper {
    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia, uint40 caller) external;

    function castVote(
        address ia,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function againstMotion(
        address ia,
        uint40 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external;

    function voteCounting(address ia, uint40 caller) external;

    // function execAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash,
    //     uint40 caller
    // ) external returns (uint256);

    function requestToBuy(
        address ia,
        bytes32 sn,
        address againstVoter,
        uint40 caller
    ) external;
}
