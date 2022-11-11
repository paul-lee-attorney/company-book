// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bos/IBookOfShares.sol";

import "../access/AccessControl.sol";

contract BOSSetting is AccessControl {
    IBookOfShares internal _bos;

    event SetBOS(address bos);

    modifier shareExist(uint32 ssn) {
        require(_bos.isShare(ssn), "shareNumber NOT exist");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setBOS(address bos) external onlyManager(1) {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }
}
