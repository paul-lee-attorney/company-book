/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../books/bom/interfaces/IBookOfMotions.sol";

import "../config/AdminSetting.sol";

contract BOMSetting is AdminSetting {
    IBookOfMotions internal _bom;

    event SetBOM(address bom);

    function setBOM(address bom) external onlyKeeper {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }
}
