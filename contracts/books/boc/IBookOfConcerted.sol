/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfConcerted {
    //#################
    //##    Event    ##
    //#################

    event AddMemberToGroup(uint40 acct, uint16 groupNo);

    event RemoveMemberFromGroup(uint40 acct, uint16 groupNo);

    event SetController(uint16 groupNo);

    //##################
    //##    写接口    ##
    //##################

    function addMemberToGroup(uint40 acct, uint16 group) external;

    function removeMemberFromGroup(uint40 acct, uint16 group) external;

    function setController(uint16 group) external;

    function updateController(bool basedOnPar) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function counterOfGroups() external view returns (uint16);

    function controller() external view returns (uint16);

    function groupNo(uint40 acct) external view returns (uint16);

    function affiliatesOfGroup(uint16 group) external view returns (uint40[]);

    function isGroup(uint16 group) external view returns (bool);

    function belongsToGroup(uint40 acct, uint16 group)
        external
        view
        returns (bool);

    function snList() external view returns (uint16[]);

    function parOfGroup(uint16 group) external view returns (uint64 parValue);

    function paidOfGroup(uint16 group) external view returns (uint64 paidPar);
}
