/* *
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IMockResults {
    //#############
    //##  Event  ##
    //#############

    event MockDealOfSell(uint16 sellerGroup, uint64 amount);

    event MockDealOfBuy(uint16 buyerGroup, uint64 amount);

    event CalculateResult(
        uint16 topGroup,
        uint64 topAmt,
        bool isOrgController,
        uint16 shareRatio
    );

    event AddAlongDeal(
        uint16 follower,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    );

    event AcceptAlongDeal(bytes32 sn);

    //#################
    //##  Write I/O  ##
    //#################

    function mockDealsOfIA(address ia) external returns (bool);

    function addAlongDeal(
        bytes32 rule,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external;

    function acceptAlongDeal(bytes32 sn) external;

    //##################
    //##    读接口    ##
    //##################

    function groupsConcerned() external view returns (uint16[]);

    function isConcernedGroup(uint16 group) external view returns (bool);

    function topGroup()
        external
        view
        returns (
            uint16 groupNum,
            uint64 amount,
            bool isOrgController,
            uint16 shareRatio,
            uint64 netIncreasedAmt
        );

    function mockResults(uint16 group)
        external
        view
        returns (
            uint64 selAmt,
            uint64 buyAmt,
            uint64 orgAmt,
            uint64 rstAmt
        );
}
