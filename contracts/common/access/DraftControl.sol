/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./AccessControl.sol";

contract DraftControl is AccessControl {
    bool public finalized;

    uint40 private _generalCounsel;

    bytes32 public constant ATTORNEYS = bytes32("Attorneys");

    // ##################
    // ##   Event      ##
    // ##################

    event SetGeneralCounsel(uint40 indexed gc);

    event LockContents();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyPending() {
        require(!finalized, "Doc is finalized");
        _;
    }

    modifier onlyFinalized() {
        require(finalized, "Doc is still pending");
        _;
    }

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

    function setGeneralCounsel(uint40 gc)
        public
        onlyPending
        ownerOrDirectKeeper
    {
        require(_generalCounsel == 0, "already set general counsel");

        _generalCounsel = gc;
        _setRoleAdmin(ATTORNEYS, _generalCounsel);

        emit SetGeneralCounsel(_generalCounsel);
    }

    function lockContents() public onlyPending onlyGC {
        abandonRole(ATTORNEYS);
        _generalCounsel = 0;
        finalized = true;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getGC() public view onlyUser returns (uint40) {
        return _generalCounsel;
    }
}
