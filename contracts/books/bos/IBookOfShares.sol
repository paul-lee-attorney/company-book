// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

pragma experimental ABIEncoderV2;

import "../../common/lib/TopChain.sol";

interface IBookOfShares {
    //##################
    //##    Event     ##
    //##################

    // ==== SharesRepo ====

    event IssueShare(
        bytes32 indexed shareNumber,
        uint64 par,
        uint64 paid,
        uint32 paidInDeadline,
        uint32 unitPrice
    );

    event PayInCapital(uint32 indexed ssn, uint64 amount, uint32 paidInDate);

    event SubAmountFromShare(uint32 indexed ssn, uint64 paid, uint64 par);

    event CapIncrease(uint64 paid, uint64 par, uint64 blocknumber);

    event CapDecrease(uint64 paid, uint64 par, uint64 blocknumber);

    event DeregisterShare(bytes32 indexed shareNumber);

    event FreezeShare(uint32 indexed ssn);

    event UpdatePaidInDeadline(uint32 indexed ssn, uint32 paidInDeadline);

    event DecreaseCleanPar(uint32 indexed ssn, uint64 paid);

    event IncreaseCleanPar(uint32 indexed ssn, uint64 paid);

    event SetPayInAmount(uint32 indexed ssn, uint64 amount, bytes32 hashLock);

    // ==== MembersRepo ====

    event SetMaxQtyOfMembers(uint8 max);

    event SetAmtBase(bool basedOnPar);

    event AddMember(uint40 indexed acct, uint16 qtyOfMembers);

    event RemoveMember(uint40 indexed acct, uint16 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sharenumber, uint40 indexed acct);

    event RemoveShareFromMember(bytes32 indexed sn, uint40 indexed acct);

    event ChangeAmtOfMember(
        uint40 indexed acct,
        uint64 paid,
        uint64 par,
        bool decrease,
        uint64 blocknumber
    );

    event DecreaseAmountFromMember(
        uint40 indexed acct,
        uint64 paid,
        uint64 par,
        uint64 blocknumber
    );

    event AddMemberToGroup(uint40 indexed acct, uint16 indexed group);

    event RemoveMemberFromGroup(uint40 indexed acct, uint16 indexed group);

    //##################
    //##    写接口    ##
    //##################

    function issueShare(
        uint40 shareholder,
        uint16 class,
        uint64 paid,
        uint64 par,
        uint32 paidInDeadline,
        uint32 issueDate,
        uint32 issuePrice
    ) external;

    // ==== PayInCapital ====

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external;

    function requestPaidInCapital(uint32 ssn, string memory hashKey) external;

    // ==== TransferShare ====

    function transferShare(
        uint32 ssn,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 unitPrice
    ) external;

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external;

    // ==== CleanPar ====

    function decreaseCleanPar(uint32 ssn, uint64 paid) external;

    function increaseCleanPar(uint32 ssn, uint64 paid) external;

    // ==== State & PaidInDeadline ====

    function freezeShare(uint32 ssn) external;

    function updatePaidInDeadline(uint32 ssn, uint32 paidInDeadline) external;

    // ==== MembersRepo ====

    function setMaxQtyOfMembers(uint8 max) external;

    function setAmtBase(bool basedOnPar) external;

    function addMemberToGroup(uint40 acct, uint16 group) external;

    function removeMemberFromGroup(uint40 acct, uint16 group) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    // ==== BookOfShares ====

    function verifyRegNum(string memory regNum) external view returns (bool);

    function maxQtyOfMembers() external view returns (uint16);

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    function paidCap() external view returns (uint64);

    function parCap() external view returns (uint64);

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64, uint64);

    function totalVotes() external view returns (uint64);

    // ==== SharesRepo ====

    function isShare(uint32 ssn) external view returns (bool);

    function cleanPar(uint32 ssn) external view returns (uint64);

    function getShare(uint32 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint64 paid,
            uint64 par,
            uint32 paidInDeadline,
            uint32 unitPrice
            // uint8 state
        );

    function sharesList() external view returns (bytes32[] memory);

    function sharenumberExist(bytes32 sharenumbre) external view returns (bool);

    // ==== PayInCapital ====

    function getLocker(uint32 ssn)
        external
        view
        returns (uint64 amount, bytes32 hashLock);

    // ==== MembersRepo ====

    function isMember(uint40 acct) external view returns (bool);

    // function indexOfMember(uint40 acct) external view returns (uint16);

    function paidOfMember(uint40 acct) external view returns (uint64 paid);

    function parOfMember(uint40 acct) external view returns (uint64 par);

    function votesInHand(uint40 acct) external view returns (uint64);

    function votesAtBlock(uint40 acct, uint64 blocknumber)
        external
        view
        returns (uint64);

    function sharesInHand(uint40 acct) external view returns (bytes32[] memory);

    function groupNo(uint40 acct) external view returns (uint16);

    function qtyOfMembers() external view returns (uint16);

    function membersList() external view returns (uint40[] memory);

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        returns (bool);

    // ==== group ====

    function isGroup(uint16 group) external view returns (bool);

    function counterOfGroups() external view returns(uint16);

    function controllor() external view returns (uint40);

    function votesOfController() external view returns (uint64);

    function votesOfGroup(uint16 group) external view returns (uint64);

    function leaderOfGroup(uint16 group) external view returns (uint64);

    function membersOfGroup(uint16 group)
        external
        view
        returns (uint40[] memory);

    function deepOfGroup(uint16 group) external view returns (uint16);

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory);
}
