/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boa//IBookOfIA.sol";

import "../access/AccessControl.sol";

import "./IBookSetting.sol";

contract BOASetting is IBookSetting, AccessControl {
    IBookOfIA internal _boa;

    event SetBOA(address boa);

    function setBOA(address boa) external onlyDirectKeeper {
        _boa = IBookOfIA(boa);
        emit SetBOA(boa);
    }
}
