/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfPledges.sol";

import "../config/AdminSetting.sol";

contract BOPSetting is AdminSetting {
    IBookOfPledges internal _bop;

    event SetBOP(address bop);

    function setBOP(address bop) external onlyBookeeper {
        _bop = IBookOfPledges(bop);
        emit SetBOP(bop);
    }
}
