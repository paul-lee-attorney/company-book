/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookkeeper {
    function pushToCoffer(
        uint8 snOfDeal,
        address ia,
        address resolution,
        bytes32 hashLock
    ) external;

    function closeDeal(
        uint8 snOfDeal,
        address ia,
        address resolution,
        bytes32 hashKey
    ) external;
}
