/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";

import "../config/AdminSetting.sol";

contract BOSSetting is AdminSetting {
    IBookOfShares private _bos;

    event SetBOS(address bos);

    modifier onlyMember() {
        require(_bos.isMember(msg.sender), "仅 股东 可操作");
        _;
    }

    modifier onlyStakeholders() {
        address sender = msg.sender;
        require(
            sender == getAdmin() ||
                sender == getBookkeeper() ||
                _bos.isMember(sender),
            "仅 利害关系方 可操作"
        );
        _;
    }

    modifier beShare(uint256 shareNumber) {
        require(_bos.shareExist(shareNumber), "股权不存在");
        _;
    }

    function setBOS(address bos) public onlyBookkeeper {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }

    function getBOS() public view returns (IBookOfShares) {
        return _bos;
    }
}
