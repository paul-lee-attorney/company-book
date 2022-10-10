/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boa/IBookOfIA.sol";

import "../access/AccessControl.sol";

contract BOASetting is AccessControl {
    IBookOfIA internal _boa;

    event SetBOA(address boa);

    function setBOA(address boa) external onlyManager(1) {
        _boa = IBookOfIA(boa);
        emit SetBOA(boa);
    }
}
