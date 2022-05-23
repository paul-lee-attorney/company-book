/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./AccessControl.sol";

contract DraftControl is AccessControl {
    uint32 private _generalCounsel;

    bytes32 public constant ATTORNEYS = bytes32("Attorneys");

    // ##################
    // ##   Event      ##
    // ##################

    event SetGeneralCounsel(uint32 indexed gc);

    event LockContents();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyGC() {
        require(_msgSender() == _generalCounsel, "not general counsel");
        _;
    }

    modifier onlyAttorney() {
        require(hasRole(ATTORNEYS, _msgSender()), "not attorney");
        _;
    }

    modifier attorneyOrKeeper() {
        require(
            hasRole(ATTORNEYS, _msgSender()) || hasRole(KEEPERS, _msgSender()),
            "not attorney or keeper"
        );
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setGeneralCounsel(uint32 gc) public ownerOrDirectKeeper {
        require(_generalCounsel == 0, "already set general counsel");

        _generalCounsel = gc;
        _setRoleAdmin(ATTORNEYS, _generalCounsel);

        emit SetGeneralCounsel(_generalCounsel);
    }

    function lockContents() public onlyGC {
        abandonRole(ATTORNEYS);
        _generalCounsel = 0;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getGC() public view returns (uint32) {
        return _generalCounsel;
    }
}
