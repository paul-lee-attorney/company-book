/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAntiDilution {
    // ################
    // ##   Event    ##
    // ################

    event SetBenchmark(uint8 indexed class, uint256 price);

    event DelBenchmark(uint8 indexed class);

    event AddObligor(uint256 indexed class, uint40 obligor);

    event RemoveObligor(uint256 indexed class, uint40 obligor);

    // ################
    // ##   Write    ##
    // ################

    function setBenchmark(uint8 class, uint256 price) external;

    function delBenchmark(uint8 class) external;

    function addObligor(uint8 class, uint40 obligor) external;

    function removeObligor(uint8 class, uint40 obligor) external;

    // ############
    // ##  read  ##
    // ############

    function isMarked(uint8 class) external view returns (bool);

    function classToMark(uint8 class) external view returns (bytes32);

    function obligors(uint8 class) external view returns (uint40[]);

    function benchmarks() external view returns (bytes32[]);

    function giftPar(
        address ia,
        bytes32 snOfDeal,
        bytes32 shareNumber
    ) external view returns (uint256);
}
