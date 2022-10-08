/* *
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./IMockResults.sol";
import "./IInvestmentAgreement.sol";

import "../../common/lib/TopChain.sol";
import "../../common/lib/MembersRepo.sol";
// import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SNParser.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/SHASetting.sol";

import "../../common/ruting/IASetting.sol";

interface IMockResults {
    //##############
    //##  Events  ##
    //##############

    event CreateMockGM(uint64 blocknumber);

    event MockDealOfSell(uint40 indexed seller, uint64 amount);

    event MockDealOfBuy(uint40 indexed buyer, uint64 amount);

    event AddAlongDeal(
        uint40 indexed follower,
        bytes32 sharenumber,
        uint64 amount
    );

    //#################
    //##  Write I/O  ##
    //#################

    function createMockGM() external;

    function mockDealOfSell(uint32 ssn, uint64 amount) external;

    function mockDealOfBuy(bytes32 sn, uint64 amount) external;

    function addAlongDeal(
        bytes32 rule,
        bytes32 shareNumber,
        uint64 amount
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function topGroup()
        external
        view
        returns (
            uint40 controllor,
            uint16 group,
            uint64 ratio
        );

    function mockResults(uint40 acct)
        external
        view
        returns (
            uint16 top,
            uint16 group,
            uint64 sum
        );
}
