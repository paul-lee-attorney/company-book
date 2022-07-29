/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IInvestmentAgreement {
    //##################
    //##    Event     ##
    //##################

    // ======== normalDeal ========

    event CreateDeal(bytes32 indexed sn, bytes32 shareNumber);

    event UpdateDeal(
        bytes32 indexed sn,
        uint32 unitPrice,
        uint64 parValue,
        uint64 paidPar,
        uint32 closingDate
    );

    event DelDeal(bytes32 indexed sn);

    event LockDealSubject(bytes32 indexed sn);

    event ReleaseDealSubject(bytes32 indexed sn);

    event ClearDealCP(
        bytes32 indexed sn,
        uint8 state,
        bytes32 hashLock,
        uint32 closingDate
    );

    event CloseDeal(bytes32 indexed sn, string hashKey);

    event RevokeDeal(bytes32 indexed sn, string hashKey);

    //##################
    //##    写接口    ##
    //##################

    // ======== InvestmentAgreement ========

    function createDeal(
        uint8 typeOfDeal,
        bytes32 shareNumber,
        uint8 class,
        uint40 buyer,
        uint16 group,
        uint16 preSSN
    ) external returns (bytes32);

    function updateDeal(
        uint16 ssn,
        uint32 unitPrice,
        uint64 parValue,
        uint64 paidPar,
        uint32 closingDate
    ) external;

    function delDeal(uint16 ssn) external;

    function lockDealSubject(uint16 ssn) external returns (bool flag);

    function releaseDealSubject(uint16 ssn) external returns (bool flag);

    // function finalizeIA() external;

    function clearDealCP(
        uint16 ssn,
        bytes32 hashLock,
        uint32 closingDate
    ) external;

    function closeDeal(uint16 ssn, string hashKey) external;

    function revokeDeal(
        uint16 ssn,
        // uint32 sigDate,
        string hashKey
    ) external;

    function takeGift(uint16 ssn) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    // ======== InvestmentAgreement ========

    function isDeal(uint16 ssn) external view returns (bool);

    function counterOfDeals() external view returns (uint16);

    function getDeal(uint16 ssn)
        external
        view
        returns (
            bytes32 sn,
            uint64 parValue,
            uint64 paidPar,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        );

    function unitPrice(uint16 ssn) external view returns (uint32);

    function closingDate(uint16 ssn) external view returns (uint32);

    function shareNumberOfDeal(uint16 ssn) external view returns (bytes32);

    function dealsList() external view returns (bytes32[]);

    function dealsConcerned(uint40 acct) external view returns (uint16[]);

    function isBuyerOfDeal(uint40 acct, uint16 seq)
        external
        view
        returns (bool);
}
