/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boa/interfaces/IBookOfAgreements.sol";
import "../../books/boa/interfaces/IAgreementCalculator.sol";

import "../access/AccessControl.sol";

contract BOASetting is AccessControl {
    IBookOfAgreements internal _boa;
    IAgreementCalculator internal _agrmtCal;

    event SetBOA(address boa);
    event SetAgrmtCalculator(address cal);

    function setBOA(address boa) external onlyDirectKeeper {
        _boa = IBookOfAgreements(boa);
        emit SetBOA(boa);
    }

    function setAgrmtCal(address cal) external onlyDirectKeeper {
        _agrmtCal = IAgreementCalculator(cal);
        emit SetAgrmtCalculator(cal);
    }
}
