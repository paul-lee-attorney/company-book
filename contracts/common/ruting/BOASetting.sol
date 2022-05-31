/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../books/boa/interfaces/IBookOfIA.sol";
import "../../books/boa/interfaces/IInvestmentAgreementCalculator.sol";

import "../access/AccessControl.sol";

contract BOASetting is AccessControl {
    IBookOfIA internal _boa;
    IInvestmentAgreementCalculator internal _agrmtCal;

    event SetBOA(address boa);
    event SetAgrmtCalculator(address cal);

    function setBOA(address boa) external onlyDirectKeeper {
        _boa = IBookOfIA(boa);
        emit SetBOA(boa);
    }

    function setAgrmtCal(address cal) external onlyDirectKeeper {
        _agrmtCal = IInvestmentAgreementCalculator(cal);
        emit SetAgrmtCalculator(cal);
    }
}
