/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./AccessControl.sol";

contract DraftControl is AccessControl {
    bytes32 public constant GENERAL_COUNSEL = bytes32("GeneralCounsel");

    bytes32 public constant ATTORNEYS = bytes32("Attorneys");

    // ##################
    // ##   Event      ##
    // ##################

    event SetGeneralCounsel(address indexed gc);

    event LockContents();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyGC() {
        require(
            msg.sender == primaryKey(GENERAL_COUNSEL),
            "not general counsel"
        );
        _;
    }

    modifier onlyAttorney() {
        require(hasRole(ATTORNEYS, msg.sender), "not attorney");
        _;
    }

    modifier attorneyOrKeeper() {
        require(hasRole(ATTORNEYS, msg.sender) || hasRole(KEEPERS, msg.sender));
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setGeneralCounsel(address gc) external onlyOwner {
        _setPrimaryKey(GENERAL_COUNSEL, gc);
        _setRoleAdmin(ATTORNEYS, GENERAL_COUNSEL);

        emit SetGeneralCounsel(gc);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getGC() public view keeperOrUser returns (address) {
        return primaryKey(GENERAL_COUNSEL);
    }
}
