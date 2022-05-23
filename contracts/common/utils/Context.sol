/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../access/AccessControl.sol";

contract Context is AccessControl {
    uint32 internal _bridgedMsgSender;

    function setMsgSender(address acct) external onlyDirectKeeper {
        _bridgedMsgSender = _rc.userNo(acct);
    }

    function _clearMsgSender() internal {
        _bridgedMsgSender = 0;
    }
}
