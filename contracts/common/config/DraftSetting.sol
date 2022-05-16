/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./AdminSetting.sol";

contract DraftSetting is AdminSetting {
    address private _generalCounsel;

    mapping(address => bool) private _isAttorney;
    address[] private _attorneys;

    // ##################
    // ##   Event      ##
    // ##################

    event SetGeneralCounsel(address gc);

    event AppointAttorney(address acct);

    event RemoveAttorney(address acct);

    event LockContents();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyGC() {
        require(msg.sender == _generalCounsel, "NOT an attorney");
        _;
    }

    modifier onlyAttorney() {
        require(_isAttorney[msg.sender], "NOT attorney");
        _;
    }

    modifier attorneyOrKeeper() {
        require(_isAttorney[msg.sender] || isKeeper(msg.sender));
        _;
    }

    // ##################
    // ##   设置端口   ##
    // ##################

    function setGeneralCounsel(address gc) external onlyAdmin {
        _generalCounsel = gc;
        grantReader(gc);

        emit SetGeneralCounsel(gc);
    }

    function appointAttorney(address acct) external onlyGC {
        _isAttorney[acct] = true;
        grantReader(acct);

        emit AppointAttorney(acct);
    }

    function removeAttorney(address acct) external onlyGC {
        delete _isAttorney[acct];
        _attorneys.removeByValue(acct);

        emit RemoveAttorney(acct);
    }

    function lockContents() public {
        _generalCounsel = address(0);

        uint256 len = _attorneys.length;
        for (uint256 i = 0; i < len; i++) delete _isAttorney[_attorneys[i]];

        _attorneys.length = 0;

        emit LockContents();
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getGC() public view returns (address) {
        return _generalCounsel;
    }

    function isAttorney() external view returns (bool) {
        return _isAttorney[msg.sender];
    }

    function attorneys() external view returns (address[]) {
        return _attorneys;
    }
}
