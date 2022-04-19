/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IShareholdersAgreement.sol";
import "../interfaces/IBookOfSHA.sol";

import "../config/AdminSetting.sol";

contract BOHSetting is AdminSetting {
    IBookOfSHA internal _boh;

    event SetBOH(address boh);

    function setBOH(address boh) external onlyKeeper {
        _boh = IBookOfSHA(boh);
        emit SetBOH(boh);
    }

    // function getBOH() public view returns (IBookOfDocuments) {
    //     return _boh;
    // }

    function getSHA() internal view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(_boh.pointer());
    }
}
