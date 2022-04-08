/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/interfaces/IBookOfPledges.sol";

import "../common/config/AdminSetting.sol";

contract BOPSetting is AdminSetting {
    IBookOfPledges internal _bop;

    event SetBOP(address bop);

    function setBOP(address bop) external onlyBookeeper {
        _bop = IBookOfPledges(bop);
        emit SetBOP(bop);
    }
}
