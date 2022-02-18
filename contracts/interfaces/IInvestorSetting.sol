/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IInvestorSetting {
    // ##################
    // ##   设置端口   ##
    // ##################

    function addInvestor(address acct) external;

    function removeInvestor(address acct) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getInvestors() external view returns (address[]);

    function isInvestor(address acct) external view returns (bool);
}
