/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boo/IBookOfOptions.sol";

// import "../access/AccessControl.sol";

contract BOOSetting {
    IBookOfOptions internal _boo;

    event SetBOO(address boo);

    function _setBOO(address boo) internal {
        _boo = IBookOfOptions(boo);
        emit SetBOO(boo);
    }
}
