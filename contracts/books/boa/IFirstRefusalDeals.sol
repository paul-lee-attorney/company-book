/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IFirstRefusalDeals {
    //###############
    //##   Event   ##
    //###############

    event ExecFirstRefusal(uint16 ssnOfOD, uint16 ssnOfFR, uint40 acct);

    event AcceptFirstRefusal(uint16 ssnOfOD, uint16 ssnOfFR, uint64 ratio);

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 ssnOfOD,
        uint16 ssnOfFR,
        uint40 acct
    ) external;

    function acceptFirstRefusal(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        returns (uint64 ratio);

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function sumOfWeight(uint16 ssnOfOD) external view returns (uint64);

    function isTargetDeal(uint16 ssnOfOD) external view returns (bool);

    function isFRDeal(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        view
        returns (bool);

    function weightOfFR(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        view
        returns (uint64);

    function ratioOfFR(uint16 ssnOfOD, uint16 ssnOfFR)
        external
        view
        returns (uint64);
}
