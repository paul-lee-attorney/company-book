/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBookOfShares {
    function issueShare(
        address shareholder,
        uint8 class,
        uint256 parValue,
        uint256 paidInDeadline,
        uint256 issueDate,
        uint256 issuePrice,
        uint256 obtainedDate,
        uint256 obtainedPrice,
        uint256 paidInDate,
        uint256 paidInAmount,
        uint8 state
    ) external;

    function payInCapital(
        uint256 shareNumber,
        uint256 amount,
        uint256 paidInDate
    ) external;

    function transferShare(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount,
        address to,
        uint256 closingDate,
        uint256 unitPrice
    ) external;

    function decreaseCapital(
        uint256 shareNumber,
        uint256 parValue,
        uint256 paidInAmount
    ) external;

    function updateShareState(uint256 shareNumber, uint8 state) external;

    function updatePaidInDeadline(uint256 shareNumber, uint256 paidInDeadline)
        external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function verifyRegNum(bytes32 regNumHash) external view returns (bool);

    function getCounterOfShare() external view returns (uint256);

    function getCounterOfClass() external view returns (uint8);

    function shareExist(uint256 shareNumber) external view returns (bool);

    function getShare(uint256 shareNumber)
        external
        view
        returns (
            address shareholder,
            uint8 class,
            uint256 parValue,
            uint256 paidInDeadline,
            uint256 issueDate,
            uint256 issuePrice,
            uint256 obtainedDate,
            uint256 obtainedPrice,
            uint256 paidInDate,
            uint256 paidInAmount,
            uint8 state
        );

    function getRegCap() external view returns (uint256);

    function getPaidInCap() external view returns (uint256);

    function getShareNumberList() external view returns (uint256[]);

    function getQtyOfShares() external view returns (uint256);

    function isMember(address acct) external view returns (bool);

    function getMember(address acct)
        external
        view
        returns (
            uint256[] sharesInHand,
            uint256 regCap,
            uint256 paidInCap
        );

    function getMemberList() external view returns (address[] memberAcctList);

    function getQtyOfMembers() external view returns (uint256 qtyOfMembers);

    function getClassMembers(uint8 class)
        external
        view
        returns (address[] classMembers);

    function getClassShares(uint8 class)
        external
        view
        returns (uint256[] classShares);
}
