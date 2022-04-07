/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfDocuments.sol";

import "../common/config/AdminSetting.sol";

contract BOASetting is AdminSetting {
    IBookOfDocuments internal _boa;

    event SetBOA(address boa);

    function setBOA(address boa) external onlyBookeeper {
        _boa = IBookOfDocuments(boa);
        emit SetBOA(boa);
    }

    // function getBOA() public view returns (IBookOfDocuments) {
    //     return _boa;
    // }
}
