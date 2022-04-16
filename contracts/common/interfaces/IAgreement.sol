/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IAgreement {
    //##################
    //##    写接口    ##
    //##################

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        address buyer,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 closingDate
    ) external;

    function delDeal(bytes32 sn) external;

    function updateDeal(
        bytes32 sn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 closingDate
    ) external;

    function finalizeIA() external;

    function clearDealCP(
        bytes32 sn,
        bytes32 hashLock,
        uint256 closingDate
    ) external;

    function closeDeal(bytes32 sn, string hashKey) external;

    function splitDeal(
        bytes32 sn,
        address buyer,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function revokeDeal(bytes32 sn, string hashKey) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    // function parToSell(address acct) external view returns (uint256 output);

    // function parToBuy(address acct) external view returns (uint256 output);

    function isDeal(bytes32 sn) external view returns (bool);

    function counterOfDeals() external view returns (uint16);

    // function typeOfIA() external view returns (uint8 output);

    function getDeal(bytes32 sn)
        external
        view
        returns (
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidInAmount,
            uint32 closingDate,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        );

    function dealsList() external view returns (bytes32[]);

    function parseSN(bytes32 sn)
        external
        view
        returns (
            uint8 typeOfDeal,
            bytes32 shareNumber,
            uint8 class,
            address seller,
            address buyer
        );
}
