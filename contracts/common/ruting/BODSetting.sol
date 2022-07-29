/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bod/IBookOfDirectors.sol";

import "../access/AccessControl.sol";

contract BODSetting is AccessControl {
    IBookOfDirectors internal _bod;

    event SetBOD(address bod);

    function setBOD(address bod) external onlyManager(1) {
        _bod = IBookOfDirectors(bod);
        emit SetBOD(bod);
    }
}
