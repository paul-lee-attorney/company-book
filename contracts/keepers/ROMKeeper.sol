// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/ROMSetting.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is
    IROMKeeper,
    ROMSetting
{

    // #############
    // ##   ROM   ##
    // #############

    function setVoteBase(bool onPar) external onlyDK {
        _rom.setVoteBase(onPar);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyDK {
        _rom.setMaxQtyOfMembers(max);
    }

    function setAmtBase(bool onPar) external onlyDK {
        _rom.setAmtBase(onPar);
    }
}
