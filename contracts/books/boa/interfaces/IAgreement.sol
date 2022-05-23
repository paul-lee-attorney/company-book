/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IAgreement {
    //##################
    //##    写接口    ##
    //##################

    function recordFRRequest(
        uint16 ssn,
        uint32 acct,
        bool basedOnPar,
        uint32 execDate
    ) external;

    function acceptFR(
        uint16 ssn,
        uint32 acct,
        uint32 acceptDate
    ) external;

    function createAlongDeal(
        bytes32 shareNumber,
        uint16 ssn,
        uint256 parValue,
        uint256 paidPar,
        uint32 createDate
    ) external;

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        uint32 buyer,
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

    function kill() external;

    function finalizeIA() external;

    function clearDealCP(
        uint16 ssn,
        bytes32 hashLock,
        uint256 closingDate
    ) external;

    function closeDeal(uint16 ssn, string hashKey) external;

    function splitDeal(
        uint16 ssn,
        uint32 buyer,
        uint256 parValue,
        uint256 paidPar
    ) external;

    function restoreDeal(uint16 ssn) external;

    function revokeDeal(uint16 ssn, string hashKey) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    function isExecParty(uint16 ssn, uint32 acct) external view returns (bool);

    function execParties(uint16 ssn) external view returns (uint32[]);

    function isSubjectDeal(uint16 ssn) external returns (bool);

    function subjectDeals() external view returns (uint16[]);

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

    function shareNumberOfDeal(uint16 ssn) external view returns (bytes32);

    function dealsList() external view returns (bytes32[]);
}
