/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfMotions.sol";

import "../config/AdminSetting.sol";

contract BOMSetting is AdminSetting {
    IBookOfMotions private _bom;

    event SetBOM(address bom);

    function setBOM(address bom) public onlyBookkeeper {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }

    function getBOM() public view returns (IBookOfMotions) {
        return _bom;
    }
}
