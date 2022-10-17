// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boa/BookOfIA.sol";

import "../access/AccessControl.sol";

contract BOASetting is AccessControl {
    BookOfIA internal _boa;

    event SetBOA(address boa);

    function setBOA(address boa) external onlyManager(1) {
        _boa = BookOfIA(boa);
        emit SetBOA(boa);
    }
}
