/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./AdminSetting.sol";

contract DraftSetting is AdminSetting {
    address private _attorney;
    // bool private _locked;

    // ##################
    // ##   Event      ##
    // ##################

    event SetAttorney(address attorney);
    event LockContents(address doc);

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyAttorney() {
        require(msg.sender == _attorney, "not Attorney");
        _;
    }

    // ##################
    // ##   设置端口   ##
    // ##################

    function lockContents() internal {
        _attorney = address(0);
        emit LockContents(this);
    }

    function setAttorney(address attorney) external adminOrBookkeeper {
        _attorney = attorney;
        emit SetAttorney(attorney);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAttorney() public view returns (address) {
        return _attorney;
    }
}
