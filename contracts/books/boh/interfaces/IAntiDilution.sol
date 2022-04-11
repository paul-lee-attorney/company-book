/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../AntiDilution.sol";

interface IAntiDilution {
    function setBenchmark(uint8 class, uint price) external;

    function delBenchmark(uint8 class) external;

    function addObligor(uint8 class, address obligor) external;

    function removeObligor(uint8 class, address obligor) external;

    // ################
    // ##  查询接口  ##
    // ################

    function benchmarkExist(uint8 class) external view returns (bool);

    function getBenchmark(uint8 class)
        external
        view
        returns (
            uint8 rank,
            uint price,
            address[] obligors
        );
}
