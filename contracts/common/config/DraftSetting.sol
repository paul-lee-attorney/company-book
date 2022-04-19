/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./AdminSetting.sol";

contract DraftSetting is AdminSetting {
    address private _generalCounsel;

    mapping(address => bool) private _attorneys;

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
        require(_attorneys[msg.sender], "NOT an attorney");
        _;
    }

    modifier attorneyOrKeeper() {
        require(_attorneys[msg.sender] || isKeeper(msg.sender));
        _;
    }

    // ##################
    // ##   设置端口   ##
    // ##################

    function setGeneralCounsel(address gc) external onlyAdmin {
        _generalCounsel = gc;
        emit SetGeneralCounsel(gc);
    }

    function appointAttorney(address acct) external onlyGC {
        _attorneys[acct] = true;
        emit AppointAttorney(acct);
    }

    function removeAttorney(address acct) external onlyGC {
        _attorneys[acct] = false;
        emit RemoveAttorney(acct);
    }

    function lockContents() public {
        _generalCounsel = address(0);

        emit LockContents();
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getGC() public view returns (address) {
        return _generalCounsel;
    }

    function isAttorney() external view returns (bool) {
        return _attorneys[msg.sender];
    }
}
