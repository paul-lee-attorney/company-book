/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOMKeeper {
    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia, uint32 proposeDate) external;

    function voteCounting(address ia) external;

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        address againstVoter
    ) external;
}
