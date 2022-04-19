/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";

import "./AdminSetting.sol";

contract BOSSetting is AdminSetting {
    IBookOfShares internal _bos;

    event SetBOS(address bos);

    modifier onlyMember() {
        require(_bos.isMember(msg.sender), "NOT Member");
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
}
