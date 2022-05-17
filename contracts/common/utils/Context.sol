/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../config/AccessControl.sol";

contract Context is AccessControl {
    address internal _msgSender;

    function setMsgSender(address acct) external onlyDirectKeeper {
        _msgSender = acct;
    }

    function _clearMsgSender() internal {
        _msgSender = address(0);
    }
}
