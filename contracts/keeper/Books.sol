/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOHSetting.sol";
import "../config/BOASetting.sol";
import "../config/BOMSetting.sol";
import "../config/BOSSetting.sol";

import "../interfaces/IBooks.sol";

// import "../common/EnumsRepo.sol";

// EnumsRepo,
contract Books is IBooks, BOHSetting, BOASetting, BOMSetting, BOSSetting {

}
