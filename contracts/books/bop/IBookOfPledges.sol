/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfPledges {
    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        bytes32 indexed sn,
        bytes32 indexed shareNumber,
        uint256 pledgedPar,
        uint40 creditor,
        uint256 guaranteedAmt
    );

    event DelPledge(bytes32 indexed sn);

    event UpdatePledge(
        bytes32 indexed sn,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    );

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        bytes32 shareNumber,
        // uint32 createDate,
        uint40 creditor,
        uint40 debtor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external;

    function delPledge(bytes32 sn) external;

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function getPledgesList(bytes32 shareNumber)
        external
        view
        returns (bytes32[]);

    function parseSN(bytes32 sn)
        external
        pure
        returns (
            bytes6 short,
            uint16 sequence,
            uint32 createDate,
            uint40 creditor
        );

    function getPledge(bytes32 sn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint256 pledgedPar,
            uint40 creditor,
            uint256 guaranteedAmt
        );

    function isPledge(bytes32 sn) external view returns (bool);

    function pledgesOf(bytes32 sn) external view returns (bytes32[]);

    function counterOfPledges() external view returns (uint16);

    function snList(uint256 sequence) external view returns (bytes32);
}