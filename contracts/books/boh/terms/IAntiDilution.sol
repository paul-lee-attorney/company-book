/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAntiDilution {
    // ################
    // ##   Event    ##
    // ################

    event SetBenchmark(uint16 indexed class, uint64 price);

    event DelBenchmark(uint16 indexed class);

    event AddObligor(uint16 indexed class, uint40 obligor);

    event RemoveObligor(uint16 indexed class, uint40 obligor);

    // ################
    // ##   Write    ##
    // ################

    function setBenchmark(uint16 class, uint32 price) external;

    function delBenchmark(uint16 class) external;

    function addObligor(uint16 class, uint40 obligor) external;

    function removeObligor(uint16 class, uint40 obligor) external;

    // ############
    // ##  read  ##
    // ############

    function isMarked(uint16 class) external view returns (bool);

    function getBenchmark(uint16 class) external view returns (uint64);

    function obligors(uint16 class) external view returns (uint40[]);

    function giftPar(
        address ia,
        bytes32 snOfDeal,
        bytes32 shareNumber
    ) external view returns (uint64);
}
