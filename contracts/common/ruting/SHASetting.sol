/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boh/IShareholdersAgreement.sol";
import "../../books/boh/IBookOfSHA.sol";

// import "../access/AccessControl.sol";

contract SHASetting {
    IBookOfSHA internal _boh;

    event SetBOH(address boh);

    function _setBOH(address boh) internal {
        _boh = IBookOfSHA(boh);
        emit SetBOH(boh);
    }

    function _getSHA() internal view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(_boh.pointer());
    }
}
