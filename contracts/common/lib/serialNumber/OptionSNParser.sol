/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library OptionSNParser {
    function typeOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[8]);
    }

    function obligorOfOpt(bytes32 sn) internal pure returns (address) {
        return address(bytes20(sn << 72));
    }

    function triggerDateOfOpt(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn));
    }

    function exerciseDaysOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[6]);
    }

    function closingDaysOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[7]);
    }

    function priceOfOpt(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes3(sn << 232));
    }
}
