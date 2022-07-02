/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bod/IBookOfDirectors.sol";

import "../access/AccessControl.sol";

import "./IBookSetting.sol";

contract BODSetting is IBookSetting, AccessControl {
    IBookOfDirectors internal _bod;

    function setBOD(address bod) external onlyDirectKeeper {
        _bod = IBookOfDirectors(bod);
        emit SetBOD(bod);
    }
}
