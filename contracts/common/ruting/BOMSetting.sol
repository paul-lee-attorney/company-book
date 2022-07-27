/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bom/IBookOfMotions.sol";

// import "../access/AccessControl.sol";

contract BOMSetting {
    IBookOfMotions internal _bom;

    event SetBOM(address bom);

    function _setBOM(address bom) internal {
        _bom = IBookOfMotions(bom);
        emit SetBOM(bom);
    }
}
