/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bom/interfaces/IBookOfMotions.sol";

import "../config/AccessControl.sol";

contract BOMSetting is AccessControl {
    IBookOfMotions internal _bom;

    event SetBOM(address bom);

    function setBOM(address bom) external onlyDirectKeeper {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }
}
