/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./interfaces/IRegCenter.sol";

contract RegCenterSetting {
    IRegCenter internal _rc;

    // ##################
    // ##   Event      ##
    // ##################

    event SetRegCenter(address rc);

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier theUser(uint32 user) {
        require(_rc.checkID(user, msg.sender), "not the user's primeKey");
        _;
    }

    modifier onlyUser() {
        require(_rc.isUser(msg.sender), "not a user");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    // shall be set up at the creation stage of a contract
    function _setRegCenter(address rc) internal {
        require(_rc == address(0), "already set regCenter");

        _rc = IRegCenter(rc);
        emit SetRegCenter(rc);
    }

    function regThisContract() public {
        _rc.regUser();
    }

    function _msgSender() internal returns (uint32) {
        return _rc.userNo(msg.sender);
    }
}
