/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bom/IBookOfMotions.sol";

import "../access/AccessControl.sol";

import "./IBookSetting.sol";

contract BOMSetting is IBookSetting, AccessControl {
    IBookOfMotions internal _bom;

    event SetBOM(address bom);

    function setBOM(address bom) external onlyDirectKeeper {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }
}
