/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bos/IBookOfShares.sol";
import "../../books/bos/IBOSCalculator.sol";

// import "../access/AccessControl.sol";

contract BOSSetting {
    IBookOfShares internal _bos;
    IBOSCalculator internal _bosCal;

    event SetBOS(address bos);

    event SetBOSCal(address cal);

    // modifier onlyMember() {
    //     require(_bos.isMember(_msgSender()), "NOT Member");
    //     _;
    // }

    modifier memberExist(uint40 acct) {
        require(_bos.isMember(acct), "member NOT exist");
        _;
    }

    // modifier onlyStakeholders() {
    //     require(
    //         _msgSender() == getOwner() ||
    //             _msgSender() == getDirectKeeper() ||
    //             _bos.isMember(_msgSender()),
    //         "NOT Stakeholders"
    //     );
    //     _;
    // }

    modifier shareExist(bytes6 ssn) {
        require(_bos.isShare(ssn), "shareNumber NOT exist");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function _setBOS(address bos) internal {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }

    function _setBOSCal(address cal) internal {
        _bosCal = IBOSCalculator(cal);
        emit SetBOSCal(cal);
    }
}
