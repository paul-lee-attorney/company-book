/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfShares {
    //##################
    //##    Event     ##
    //##################

    // ==== SharesRepo ====

    event IssueShare(
        bytes32 indexed shareNumber,
        uint64 parValue,
        uint64 paidPar,
        uint32 paidInDeadline,
        uint32 unitPrice
    );

    event PayInCapital(uint32 indexed ssn, uint64 amount, uint32 paidInDate);

    event SubAmountFromShare(
        uint32 indexed ssn,
        uint64 parValue,
        uint64 paidPar
    );

    event CapIncrease(
        uint64 par,
        uint64 regCap,
        uint64 paid,
        uint64 paidCap,
        uint64 blocknumber
    );

    event CapDecrease(
        uint64 par,
        uint64 regCap,
        uint64 paid,
        uint64 paidCap,
        uint64 blocknumber
    );

    event DeregisterShare(bytes32 indexed shareNumber);

    event UpdateShareState(uint32 indexed ssn, uint8 state);

    event UpdatePaidInDeadline(uint32 indexed ssn, uint32 paidInDeadline);

    event DecreaseCleanPar(uint32 ssn, uint64 paidPar);

    event IncreaseCleanPar(uint32 ssn, uint64 paidPar);

    event SetPayInAmount(uint32 ssn, uint64 amount, bytes32 hashLock);

    // ==== MembersRepo ====

    event SetMaxQtyOfMembers(uint16 max);

    event AddMember(uint40 indexed acct, uint16 qtyOfMembers);

    event RemoveMember(uint40 indexed acct, uint16 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sn, uint40 acct);

    event RemoveShareFromMember(bytes32 indexed sn, uint40 acct);

    event IncreaseAmountToMember(
        uint40 indexed acct,
        uint64 parValue,
        uint64 paidPar,
        uint64 blocknumber
    );

    event DecreaseAmountFromMember(
        uint40 indexed acct,
        uint64 parValue,
        uint64 paidPar,
        uint64 blocknumber
    );

    // ==== Group ====

    event AddMemberToGroup(uint40 acct, uint16 groupNo);

    event RemoveMemberFromGroup(uint40 acct, uint16 groupNo);

    event SetController(uint16 groupNo);

    //##################
    //##    写接口    ##
    //##################

    function issueShare(
        uint40 shareholder,
        uint8 class,
        uint64 parValue,
        uint64 paidPar,
        uint32 paidInDeadline,
        uint32 issueDate,
        uint32 issuePrice
    ) external;

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external;

    function requestPaidInCapital(uint32 ssn, string hashKey) external;

    function transferShare(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar,
        uint40 to,
        uint32 unitPrice
    ) external;

    function decreaseCapital(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external;

    // ==== SharesRepo ====

    function decreaseCleanPar(uint32 ssn, uint64 paidPar) external;

    function increaseCleanPar(uint32 ssn, uint64 paidPar) external;

    function updateShareState(uint32 ssn, uint8 state) external;

    function updatePaidInDeadline(uint32 ssn, uint32 paidInDeadline) external;

    // ==== GroupsRepo ====

    function addMemberToGroup(uint40 acct, uint16 group) external;

    function removeMemberFromGroup(uint40 acct, uint16 group) external;

    function setController(uint16 group) external;

    // ==== MembersRepo ====

    function setMaxQtyOfMembers(uint16 max) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function verifyRegNum(string regNum) external view returns (bool);

    // ==== SharesRepo ====

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint8);

    function regCap() external view returns (uint64 par);

    function paidCap() external view returns (uint64 paid);

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 par, uint64 paid);

    function totalVote() external view returns (uint64 vote);

    function totalVoteAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 vote);

    function isShare(uint32 ssn) external view returns (bool);

    function snList() external view returns (bytes32[]);

    function cleanPar(uint32 ssn) external view returns (uint64);

    function getShare(uint32 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint64 parValue,
            uint64 paidPar,
            uint32 paidInDeadline,
            uint32 unitPrice,
            uint8 state
        );

    function getLocker(uint32 ssn)
        external
        view
        returns (uint64 amount, bytes32 hashLock);

    // ========== MembersRepo ==============

    function maxQtyOfMembers() external view returns (uint16);

    function isMember(uint40 acct) external view returns (bool);

    function members() external view returns (uint40[]);

    function qtyOfMembersAtBlock(uint64 blockNumber)
        external
        view
        returns (uint16);

    function parInHand(uint40 acct) external view returns (uint64 par);

    function paidInHand(uint40 acct) external view returns (uint64 paid);

    function voteInHand(uint40 acct) external view returns (uint64 vote);

    function votesAtBlock(uint40 acct, uint64 blockNumber)
        external
        view
        returns (uint64 vote);

    function sharesInHand(uint40 acct) external view returns (bytes32[]);

    // ========== GroupsRepo ==============

    function counterOfGroups() external view returns (uint16);

    function controller() external view returns (uint16);

    function groupNo(uint40 acct) external view returns (uint16);

    function membersOfGroup(uint16 group) external view returns (uint40[]);

    function isGroup(uint16 group) external view returns (bool);

    function groupsList() external view returns (uint16[]);
}
