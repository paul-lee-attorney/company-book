/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";

import "../config/AdminSetting.sol";

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
            sender == getAdmin() ||
                sender == getBookeeper() ||
                _bos.isMember(sender),
            "NOT Stakeholders"
        );
        _;
    }

    modifier beShare(uint256 shareNumber) {
        require(_bos.shareExist(shareNumber), "shareNumber NOT exist");
        _;
    }

    function setBOS(address bos) external onlyBookeeper {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }

    function getBOS() external view returns (address) {
        return address(_bos);
    }
}
