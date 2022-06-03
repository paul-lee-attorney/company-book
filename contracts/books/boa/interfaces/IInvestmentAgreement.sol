/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IInvestmentAgreement {
    //##################
    //##    写接口    ##
    //##################

    // ======== FristRefusal ========

    function execFirstRefusalRight(
        uint16 ssn,
        bool basedOnPar,
        uint32 acct,
        uint32 execDate,
        bytes32 sigHash
    ) external;

    function acceptFR(
        uint16 ssn,
        uint32 acct,
        uint32 acceptDate,
        bytes32 sigHash
    ) external;

    // ======== InvestmentAgreement ========

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        uint32 buyer,
        uint16 group,
        uint16 preSSN
    ) external returns (bytes32 sn);

    function updateDeal(
        uint16 ssn,
        uint256 unitPrice,
        uint256 parValue,
        uint256 paidPar,
        uint32 closingDate
    ) external;

    function delDeal(uint16 sn) external;

    function kill() external;

    function lockDealSubject(uint16 ssn, uint32 lockDate)
        external
        returns (bool flag);

    function releaseDealSubject(uint16 ssn, uint32 releaseDate)
        external
        returns (bool flag);

    function finalizeIA() external;

    function clearDealCP(
        uint16 ssn,
        uint32 sigDate,
        bytes32 hashLock,
        uint256 closingDate
    ) external;

    function closeDeal(
        uint16 ssn,
        uint32 sigDate,
        string hashKey
    ) external;

    function revokeDeal(
        uint16 ssn,
        uint32 sigDate,
        string hashKey
    ) external;

    function takeGift(
        uint16 ssn,
        uint32 caller,
        uint32 sigDate
    ) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    // ======== FirstRefusal ========

    function counterOfFR(uint16 ssn) external view returns (uint16);

    function sumOfWeight(uint16 ssn) external view returns (uint16);

    function isTargetDeal(uint16 ssn) public view returns (bool);

    function frDeals(uint16 ssn) external view returns (uint16[]);

    // ======== InvestmentAgreement ========

    function isDeal(uint16 ssn) external view returns (bool);

    function counterOfDeals() external view returns (uint16);

    function getDeal(uint16 ssn)
        external
        view
        returns (
            bytes32 sn,
            uint256 parValue,
            uint256 paidPar,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        );

    function unitPrice(uint16 ssn) external view returns (uint256);

    function closingDate(uint16 ssn) external view returns (uint32);

    function shareNumberOfDeal(uint16 ssn) external view returns (bytes32);

    function dealsList() external view returns (bytes32[]);
}
