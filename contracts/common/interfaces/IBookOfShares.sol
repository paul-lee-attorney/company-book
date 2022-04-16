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
        bytes32 shareNumber,
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

    function updateShareState(bytes32 shareNumber, uint8 state) external;

    function updatePaidInDeadline(bytes32 shareNumber, uint256 paidInDeadline)
        external;

    function increaseCleanPar(bytes32 shareNumber, uint256 parValue) external;

    function decreaseCleanPar(bytes32 shareNumber, uint256 parValue) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function regCap() external view returns (uint256);

    function paidInCap() external view returns (uint256);

    function snList() external view returns (bytes32[]);

    function getShare(bytes32 shareNumber)
        external
        view
        returns (
            uint256 parValue,
            uint256 paidPar,
            uint256 cleanPar,
            uint256 paidInDeadline,
            uint256 unitPrice,
            uint8 state
        );

    function isShare(bytes32 shareNumber) external view returns (bool);

    function sharesList() external view returns (bytes32[]);

    function getPreSN(bytes32 shareNumber)
        external
        view
        returns (bytes32 preSN);

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

    function maxQtyOfMembers() external view returns (uint8);

    function verifyRegNum(string regNum) external view returns (bool);

    function counterOfShares() external view returns (uint256);

    function counterOfClasses() external view returns (uint8);

    // ========== PledgesRepo ==============

    function pledges(bytes32 sn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint256 pledgedPar,
            address creditor,
            uint256 guaranteedAmt
        );

    function pledgeExist(bytes32 sn) external view returns (bool);

    function pledgeQue(bytes32 shareNumber, uint256 sequenceNumber)
        external
        view
        returns (bytes32);

    function lenOfPledgeQue(bytes32 shareNumber)
        external
        view
        returns (uint256);

    function cleanPar(bytes32 shareNumber) external view returns (uint256);

    function getPledgesList(bytes32 shareNumber)
        external
        view
        returns (bytes32[]);
}
