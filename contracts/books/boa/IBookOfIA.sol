// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IDocumentsRepo.sol";

interface IBookOfIA is IDocumentsRepo {
    //##################
    //##    写接口    ##
    //##################

    // ======== BookOfIA ========

    function circulateIA(address ia) external;

    function createFRDeals(address ia, uint40 creator)
        external
        returns (address frd);

    function createMockResults(address ia) external returns (address mock);

    //##################
    //##    读接口    ##
    //##################

    // ======== BookOfIA ========

    function typeOfIA(address ia) external view returns (uint8 output);

    function frDealsOfIA(address ia) external view returns (address);

    function mockResultsOfIA(address ia) external view returns (address);
}
