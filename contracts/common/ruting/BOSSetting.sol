/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bos/IBookOfShares.sol";
import "../../books/bos/IBOSCalculator.sol";

import "../access/AccessControl.sol";

import "./IBookSetting.sol";

contract BOSSetting is IBookSetting, AccessControl {
    IBookOfShares internal _bos;
    IBOSCalculator internal _bosCal;


    modifier onlyMember() {
        require(_bos.isMember(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_bos.isMember(acct), "member NOT exist");
        _;
    }

    modifier onlyStakeholders() {
        require(
            _msgSender() == getOwner() ||
                _msgSender() == getDirectKeeper() ||
                _bos.isMember(_msgSender()),
            "NOT Stakeholders"
        );
        _;
    }

    modifier shareExist(bytes6 ssn) {
        require(_bos.isShare(ssn), "shareNumber NOT exist");
        _;
    }

    function setBOS(address bos) external onlyDirectKeeper {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }

    function setBOSCal(address cal) external onlyDirectKeeper {
        _bosCal = IBOSCalculator(cal);
        emit SetBOSCal(cal);
    }
}
