// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/rom/IRegisterOfMembers.sol";

import "../access/AccessControl.sol";

contract ROMSetting is AccessControl {
    IRegisterOfMembers internal _rom;

    event SetROM(address rom);

    modifier onlyMember() {
        require(_rom.isMember(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_rom.isMember(acct), "member NOT exist");
        _;
    }

    function setROM(address rom) external onlyDK {
        _rom = IRegisterOfMembers(rom);
        emit SetROM(rom);
    }
}
