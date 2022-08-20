/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/bos/IBookOfShares.sol";
import "../../books/bos/IBOSCalculator.sol";

import "../access/AccessControl.sol";

contract BOSSetting is AccessControl {
    IBookOfShares internal _bos;
    IBOSCalculator internal _bosCal;

    event SetBOS(address bos);

    event SetBOSCal(address cal);

    modifier onlyMember() {
        require(_bos.isMember(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_bos.isMember(acct), "member NOT exist");
        _;
    }

    // modifier onlyStakeholders() {
    //     require(
    //         _msgSender() == getManagerKey(0) ||
    //             _msgSender() == getManager(1) ||
    //             _bos.isMember(_msgSender()),
    //         "NOT Stakeholders"
    //     );
    //     _;
    // }

    modifier shareExist(uint32 ssn) {
        require(_bos.isShare(ssn), "shareNumber NOT exist");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setBOS(address bos) external onlyManager(1) {
        _bos = IBookOfShares(bos);
        emit SetBOS(bos);
    }

    function setBOSCal(address cal) external onlyManager(1) {
        _bosCal = IBOSCalculator(cal);
        emit SetBOSCal(cal);
    }
}
