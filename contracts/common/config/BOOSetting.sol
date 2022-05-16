/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boo/interfaces/IBookOfOptions.sol";

import "../config/AdminSetting.sol";

contract BOOSetting is AdminSetting {
    IBookOfOptions internal _boo;

    event SetBOO(address boo);

    function setBOO(address boo) external onlyDirectKeeper {
        _boo = IBookOfOptions(boo);
        emit SetBOO(boo);
    }
}
