/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boc/IBookOfConcerted.sol";

import "../access/AccessControl.sol";

contract BOCSetting is AccessControl {
    IBookOfConcerted internal _boc;

    event SetBOC(address boc);

    function setBOC(address boc) external onlyManager(1) {
        _boc = IBookOfConcerted(boc);
        emit SetBOC(boc);
    }
}
