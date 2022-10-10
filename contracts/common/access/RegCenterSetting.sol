// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

contract RegCenterSetting {
    IRegCenter internal _rc;

    // ##################
    // ##   Event      ##
    // ##################

    event SetRegCenter(address rc);

    // ##################
    // ##    写端口    ##
    // ##################

    // shall be set up at the creation stage of a contract
    function _setRegCenter(address rc) internal {
        require(address(_rc) == address(0), "already set regCenter");

        _rc = IRegCenter(rc);
        emit SetRegCenter(rc);
    }

    function _msgSender() internal returns (uint40) {
        return _rc.userNo(msg.sender);
    }
}
