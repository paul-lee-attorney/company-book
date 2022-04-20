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

    function delDeal(uint16 sn) external;

    function updateDeal(
        uint16 sn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 closingDate
    ) external;

    function finalizeIA() external;

    function clearDealCP(
        uint16 ssn,
        bytes32 hashLock,
        uint256 closingDate
    ) external;

    function closeDeal(uint16 ssn, string hashKey) external;

    function splitDeal(
        uint16 ssn,
        address buyer,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function restoreDeal(uint16 ssn) external;

    function revokeDeal(uint16 ssn, string hashKey) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    function isDeal(uint16 ssn) external view returns (bool);

    function counterOfDeals() external view returns (uint16);

    function getDeal(uint16 ssn)
        external
        view
        returns (
            bytes32 sn,
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            uint32 closingDate,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        );

    function dealsList() external view returns (bytes32[]);
}
