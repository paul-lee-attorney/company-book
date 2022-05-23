/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../AntiDilution.sol";

interface IAntiDilution {
    function setBenchmark(uint8 class, uint256 price) external;

    function delBenchmark(uint8 class) external;

    function addObligor(uint8 class, uint32 obligor) external;

    function removeObligor(uint8 class, uint32 obligor) external;

    // ################
    // ##  查询接口  ##
    // ################

    function benchmarkExist(uint8 class) external view returns (bool);

    function getBenchmark(uint8 class)
        external
        view
        returns (
            uint8 rank,
            uint256 price,
            uint32[] obligors
        );
}
