/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IAdminSetting.sol";

contract AdminSetting is IAdminSetting {
    address private _admin;

    address private _backup;

    address private _bookkeeper;

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier adminOrBookkeeper() {
        require(
            msg.sender == _bookkeeper || msg.sender == _admin,
            "not bookkeeper or admin"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "not Admin");
        _;
    }

    modifier originedFromAdmin() {
        require(tx.origin == _admin, "not origined from Admin");
        _;
    }

    modifier onlyBackup() {
        require(msg.sender == _backup, "not backup admin");
        _;
    }

    modifier onlyBookkeeper() {
        require(msg.sender == _bookkeeper, "not bookkeeper");
        _;
    }

    modifier onceOnly(address add) {
        require(add == address(0), "role has been set already");
        _;
    }

    modifier onlyStakeholders() {
        address sender = msg.sender;
        require(
            sender == _admin || sender == _bookkeeper,
            "not interested party"
        );
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(address admin, address bookkeeper)
        public
        onceOnly(_admin)
        onceOnly(_bookkeeper)
    {
        _admin = admin;
        _bookkeeper = bookkeeper;
        emit Init(admin, bookkeeper);
    }

    function setBackup(address backup) public onlyAdmin {
        _backup = backup;
        emit SetBackup(backup);
    }

    function takeoverAdmin() public onlyBackup {
        _admin = msg.sender;
        emit TakeoverAdmin(_admin);
    }

    function abandonAdmin() public onlyBookkeeper originedFromAdmin {
        _admin = address(0);
        _backup = address(0);
        emit AbandonAdmin();
    }

    function setBookkeeper(address bookkeeper) public onlyBookkeeper {
        _bookkeeper = bookkeeper;
        emit SetBookkeeper(bookkeeper);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getAdmin() public view returns (address) {
        return _admin;
    }

    function getBackup() public view returns (address) {
        return _backup;
    }

    function getBookkeeper() public view returns (address) {
        return _bookkeeper;
    }
}
