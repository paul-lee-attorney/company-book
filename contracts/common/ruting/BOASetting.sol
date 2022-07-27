/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boa/IBookOfIA.sol";

// import "../access/AccessControl.sol";

contract BOASetting {
    IBookOfIA internal _boa;

    event SetBOA(address boa);

    function _setBOA(address boa) internal {
        _boa = IBookOfIA(boa);
        emit SetBOA(boa);
    }
}
