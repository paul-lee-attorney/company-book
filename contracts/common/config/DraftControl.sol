/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./AccessControl.sol";

contract DraftControl is AccessControl {
    bytes32 internal constant _GENERAL_COUNSEL = bytes32("GeneralCounsel");

    bytes32 internal constant _ATTORNEYS = bytes32("Attorneys");

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
            msg.sender == _primaryKey(_GENERAL_COUNSEL),
            "not general counsel"
        );
        _;
    }

    modifier onlyAttorney() {
        require(hasRole(_ATTORNEYS, msg.sender), "not attorney");
        _;
    }

    modifier attorneyOrKeeper() {
        require(
            hasRole(_ATTORNEYS, msg.sender) || hasRole(_KEEPERS, msg.sender)
        );
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setGeneralCounsel(address gc) external onlyOwner {
        _setPrimaryKey(_GENERAL_COUNSEL, gc);
        _setRoleAdmin(_ATTORNEYS, _GENERAL_COUNSEL);

        emit SetGeneralCounsel(gc);
    }

    // function lockContents() external onlyGC {
    //     _abandonRole(_ATTORNEYS);
    //     _quitPositon(_GENERAL_COUNSEL);
    //     emit LockContents();
    // }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getGC() public view keeperOrUser returns (address) {
        return _primaryKey(_GENERAL_COUNSEL);
    }
}
