// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bom/IBookOfMotions.sol";

import "../access/AccessControl.sol";

contract BOMSetting is AccessControl {
    IBookOfMotions internal _bom;

    event SetBOM(address bom);

    function setBOM(address bom) external onlyManager(1) {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }
}
