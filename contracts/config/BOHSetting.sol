/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IShareholdersAgreement.sol";
import "../interfaces/IBookOfDocuments.sol";

import "../config/AdminSetting.sol";

contract BOHSetting is AdminSetting {
    IBookOfDocuments private _boh;

    event SetBOH(address boh);

    function setBOH(address boh) public onlyBookkeeper {
        _boh = IBookOfDocuments(boh);
        emit SetBOH(boh);
    }

    function getBOH() public view returns (IBookOfDocuments) {
        return _boh;
    }

    function getSHA() public view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(_boh.getTheOne());
    }
}
