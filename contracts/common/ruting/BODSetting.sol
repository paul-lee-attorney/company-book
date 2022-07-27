/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bod/IBookOfDirectors.sol";

// import "../access/AccessControl.sol";

contract BODSetting {
    IBookOfDirectors internal _bod;

    event SetBOD(address bod);

    function _setBOD(address bod) internal {
        _bod = IBookOfDirectors(bod);
        emit SetBOD(bod);
    }
}
