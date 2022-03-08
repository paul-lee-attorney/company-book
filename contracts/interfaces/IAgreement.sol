/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IAgreement {
    //##################
    //##    写接口    ##
    //##################

    function setDeal(
        uint8 sn,
        uint256 shareNumber,
        uint8 class,
        address seller,
        address buyer,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 closingDate
    ) external;

    function delDeal(uint8 sn) external;

    function finalizeIA() external;

    function clearDealCP(
        uint8 sn,
        bytes32 hashLock,
        uint256 closingDate
    ) external;

    function closeDeal(uint8 sn, string hashKey) external;

    function revokeDeal(uint8 sn, string hashKey) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    function parToSell(address acct) external view returns (uint256 parValue);

    function parToBuy(address acct) external view returns (uint256 parValue);

    function getDeal(uint8 sn)
        external
        view
        returns (
            uint256 shareNumber,
            uint8 class,
            address seller,
            address buyer,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidInAmount,
            uint256 closingDate,
            uint8 typeOfDeal, // 1-CI 2-ST(to 3rd) 3-ST(internal)
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        );

    function qtyOfDeals() external view returns (uint8);

    function typeOfIA() external view returns (uint8);
}
