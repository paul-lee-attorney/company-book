/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfOptions.sol";

import "../config/AdminSetting.sol";

contract BOOSetting is AdminSetting {
    IBookOfOptions internal _boo;

    event SetBOO(address boo);

    function setBOO(address boo) external onlyKeeper {
        _boo = IBookOfOptions(boo);
        emit SetBOO(boo);
    }
}
