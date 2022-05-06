/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfAgreements.sol";
import "../interfaces/IAgreementCalculator.sol";

import "../config/AdminSetting.sol";

contract BOASetting is AdminSetting {
    IBookOfAgreements internal _boa;
    IAgreementCalculator internal _agrmtCal;

    event SetBOA(address boa);
    event SetAgrmtCalculator(address cal);

    function setBOA(address boa) external onlyKeeper {
        _boa = IBookOfAgreements(boa);
        emit SetBOA(boa);
    }

    function setBOACal(address cal) external onlyKeeper {
        _agrmtCal = IAgreementCalculator(cal);
        emit SetAgrmtCalculator(cal);
    }
}
