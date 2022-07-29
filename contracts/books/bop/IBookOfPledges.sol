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
        uint64 pledgedPar,
        uint40 creditor,
        uint64 guaranteedAmt
    );

    event DelPledge(bytes32 indexed sn);

    event UpdatePledge(
        bytes32 indexed sn,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    );

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        bytes32 shareNumber,
        uint40 creditor,
        uint40 debtor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external;

    function delPledge(bytes6 ssn) external;

    function updatePledge(
        bytes6 ssn,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function pledgesOf(bytes32 shareNumber) external view returns (bytes32[]);

    function counterOfPledges() external view returns (uint16);

    function isPledge(bytes6 ssn) external view returns (bool);

    function snList() external view returns (bytes32[]);

    function getPledge(bytes6 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint64 pledgedPar,
            uint40 creditor,
            uint64 guaranteedAmt
        );
}
