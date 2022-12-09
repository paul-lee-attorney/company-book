// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../access/AccessControl.sol";

import "../../books/boa/IInvestmentAgreement.sol";

contract IASetting is AccessControl {
    IInvestmentAgreement internal _ia;

    //##################
    //##   Modifier   ##
    //##################

    modifier dealExist(uint16 ssn) {
        _ia.isDeal(ssn);
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setIA(address ia) external onlyDK {
        _ia = IInvestmentAgreement(ia);
    }
}
