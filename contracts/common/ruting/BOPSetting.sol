/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bop/IBookOfPledges.sol";

import "../access/AccessControl.sol";

contract BOPSetting is AccessControl {
    IBookOfPledges internal _bop;

    event SetBOP(address bop);

    function setBOP(address bop) external onlyManager(1) {
        _bop = IBookOfPledges(bop);
        emit SetBOP(bop);
    }
}
