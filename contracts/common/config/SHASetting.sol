/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boh/interfaces/IShareholdersAgreement.sol";
import "../../books/boh/interfaces/IBookOfSHA.sol";

import "../config/AdminSetting.sol";

contract SHASetting is AdminSetting {
    IBookOfSHA internal _boh;

    event SetBOH(address boh);

    function setBOH(address boh) external onlyDirectKeeper {
        _boh = IBookOfSHA(boh);
        emit SetBOH(boh);
    }

    function _getSHA() internal view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(_boh.pointer());
    }
}
