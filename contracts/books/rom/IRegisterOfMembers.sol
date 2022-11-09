// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/TopChain.sol";

interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    event CapIncrease(uint64 paid, uint64 par, uint64 blocknumber);

    event CapDecrease(uint64 paid, uint64 par, uint64 blocknumber);

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

    function capIncrease(uint64 paid, uint64 par) external;

    function capDecrease(uint64 paid, uint64 par) external;

    function setMaxQtyOfMembers(uint8 max) external;

    function setAmtBase(bool basedOnPar) external;

    function addMember(uint40 acct) external;

    function addShareToMember(uint32 ssn, uint40 acct) external;

    function removeShareFromMember(uint32 ssn, uint40 acct) external;

    function changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) external;

    function addMemberToGroup(uint40 acct, uint16 group) external;

    function removeMemberFromGroup(uint40 acct, uint16 group) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function maxQtyOfMembers() external view returns (uint16);

    function paidCap() external view returns (uint64);

    function parCap() external view returns (uint64);

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64, uint64);

    function totalVotes() external view returns (uint64);

    function sharesList() external view returns (bytes32[] memory);

    function sharenumberExist(bytes32 sharenumbre) external view returns (bool);

    function isMember(uint40 acct) external view returns (bool);

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

    function counterOfGroups() external view returns (uint16);

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
