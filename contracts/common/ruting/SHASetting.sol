// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boh/IShareholdersAgreement.sol";
import "../../books/boh/IBookOfSHA.sol";

import "../access/AccessControl.sol";

contract SHASetting is AccessControl {
    IBookOfSHA internal _boh;

    event SetBOH(address boh);

    function setBOH(address boh) external onlyManager(1) {
        _boh = IBookOfSHA(boh);
        emit SetBOH(boh);
    }

    function _getSHA() internal view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(_boh.pointer());
    }
}
