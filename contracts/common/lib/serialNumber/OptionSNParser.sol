/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library OptionSNParser {
    function typeOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function sequenceOfOpt(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 8));
    }

    function triggerDateOfOpt(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 24));
    }

    function shortOfOpt(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn << 8);
    }

    function exerciseDaysOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[7]);
    }

    function closingDaysOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[8]);
    }

    function obligorOfOpt(bytes32 sn) internal pure returns (address) {
        return address(bytes20(sn << 72));
    }

    function priceOfOpt(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes3(sn << 232));
    }

    function shortShareNumberOfFt(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn);
    }

    function parValueOfFt(bytes32 sn) internal pure returns (uint256) {
        return uint256(uint208(sn));
    }
}
