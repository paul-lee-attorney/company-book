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

    function increaseCleanPar(bytes32 shareNumber, uint256 parValue) external;

    function decreaseCleanPar(bytes32 shareNumber, uint256 parValue) external;

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
            uint256 paidInAmount,
            uint256 cleanPar,
            uint256 paidInDeadline,
            uint256 issueDate,
            uint256 unitPrice,
            uint8 state
        );

    function shareExist(uint256 shareNumber) external view returns (bool);

    function sharesList() external view returns (uint256[]);

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

    function counterOfClass() external view returns (uint8);

    // ========== PledgesRepo ==============

    function pledges(bytes32 sn)
        external
        view
        returns (
            uint256 shareNumber,
            uint256 pledgedPar,
            address creditor,
            uint256 guaranteedAmt
        );

    function pledgeExist(bytes32 sn) external view returns (bool);

    function pledgeQue(uint256 shareNumber, uint256 sequenceNumber)
        external
        view
        returns (bytes32);

    function lenOfPledgeQue(uint256 shareNumber)
        external
        view
        returns (uint256);

    function cleanPar(uint256 shareNumber) external view returns (uint256);

    function getPledgesList(uint256 shareNumber)
        external
        view
        returns (bytes32[]);
}
