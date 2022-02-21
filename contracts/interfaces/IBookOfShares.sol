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

    function regCap() external view returns (uint256);

    function paidInCap() external view returns (uint256);

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

    function shareExist(uint256 shareNumber) external view returns (bool);

    function sharesList() external view returns (uint256[]);

    function membersOfClass(uint8 class) external view returns (address[]);

    function sharesOfClass(uint8 class) external view returns (uint256[]);

    function isMember(address acct) external view returns (bool);

    function getMember(address acct)
        external
        view
        returns (
            uint256[] sharesInHand,
            uint256 parValue,
            uint256 paidInAmount
        );

    function membersList() external view returns (address[]);

    function verifyRegNum(bytes32 regNumHash) external view returns (bool);

    function counterOfShares() external view returns (uint256);

    function counterOfClass() external view returns (uint8);
}
