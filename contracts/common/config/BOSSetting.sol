/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";
import "../interfaces/IBOSCalculator.sol";

import "./AdminSetting.sol";

contract BOSSetting is AdminSetting {
    IBookOfShares internal _bos;
    IBOSCalculator internal _bosCal;

    event SetBOS(address bos);
    event SetBOSCal(address cal);

    modifier onlyMember() {
        require(_bos.isMember(msg.sender), "NOT Member");
        _;
    }

    modifier memberExist(address acct) {
        require(_bos.isMember(acct), "member NOT exist");
        _;
    }

    modifier onlyStakeholders() {
        address sender = msg.sender;
        require(
            sender == getAdmin() || sender == getGK() || _bos.isMember(sender),
            "NOT Stakeholders"
        );
        _;
    }

    modifier shareExist(bytes6 ssn) {
        require(_bos.isShare(ssn), "shareNumber NOT exist");
        _;
    }

    function setBOS(address bos) external onlyKeeper {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }

    function setBOSCal(address cal) external onlyKeeper {
        _bosCal = IBOSCalculator(cal);
        emit SetBOSCal(cal);
    }
}
