/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bop/IBookOfPledges.sol";

// import "../access/AccessControl.sol";

contract BOPSetting {
    IBookOfPledges internal _bop;

    event SetBOP(address bop);

    function _setBOP(address bop) internal {
        _bop = IBookOfPledges(bop);
        emit SetBOP(bop);
    }
}
