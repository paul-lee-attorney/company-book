/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfShares {
    function issueShare(
        address shareholder,
        uint8 class,
        uint256 parValue,
        uint256 paidInAmount,
        uint256 paidInDeadline,
        uint256 issueDate,
        uint256 unitPrice
    ) external;

    function payInCapital(
        bytes6 ssn,
        uint256 amount,
        uint256 paidInDate
    ) external;

    function transferShare(
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidInAmount,
        address to,
        uint256 closingDate,
        uint256 unitPrice
    ) external;

    function decreaseCapital(
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) external;

    function updateShareState(bytes6 ssn, uint8 state) external;

    function updatePaidInDeadline(bytes6 ssn, uint256 paidInDeadline) external;

    function increaseCleanPar(bytes6 ssn, uint256 parValue) external;

    function decreaseCleanPar(bytes6 ssn, uint256 parValue) external;

    function addMemberToGroup(address acct, uint16 group) external;

    function removeMemberFromGroup(address acct, uint16 group) external;

    function setController(uint16 group) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function regCap() external view returns (uint256);

    function paidCap() external view returns (uint256);

    function isShare(bytes6 ssn) external view returns (bool);

    function counterOfShares() external view returns (uint256);

    function counterOfClasses() external view returns (uint8);

    function snList() external view returns (bytes32[]);

    function getShare(bytes6 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint256 parValue,
            uint256 paidPar,
            uint256 cleanPar,
            uint256 paidInDeadline,
            uint256 unitPrice,
            uint8 state
        );

    function verifyRegNum(string regNum) external view returns (bool);

    // ========== GroupsRepo ==============

    function isGroup(uint16 group) external view returns (bool);

    function membersOfGroup(uint16 group) external view returns (address[]);

    function groupNo(address acct) external view returns (uint16);

    function counterOfGroups() external view returns (uint16);

    function controller() external view returns (uint16);

    function groupsList() external view returns (uint16[]);

    // ========== MembersRepo ==============

    function isMember(address acct) external view returns (bool);

    function sharesInHand(address acct) external view returns (bytes32[]);

    function parInHand(address acct) external view returns (uint256);

    function paidInHand(address acct) external view returns (uint256);

    function maxQtyOfMembers() external view returns (uint8);

    function membersList() external view returns (address[]);
}
