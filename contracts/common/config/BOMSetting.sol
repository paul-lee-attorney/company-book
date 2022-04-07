/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfMotions.sol";

import "../common/config/AdminSetting.sol";

contract BOMSetting is AdminSetting {
    IBookOfMotions internal _bom;

    event SetBOM(address bom);

    function setBOM(address bom) external onlyBookeeper {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }
}
