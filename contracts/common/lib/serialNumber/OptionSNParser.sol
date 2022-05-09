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

    function rateOfOpt(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 72));
    }

    function parValueOfOpt(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 104));
    }

    function paidParOfOpt(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 136));
    }

    function logOperator(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[21]);
    }

    function compOperator_1(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[22]);
    }

    function para_1(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 176));
    }

    function compOperator_2(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[27]);
    }

    function para_2(bytes32 sn) internal pure returns (uint256) {
        return uint256(uint32(sn));
    }

    function checkConditions(
        bytes32 sn,
        uint256 data_1,
        uint256 data_2
    ) internal pure returns (bool) {
        bool flag_1;
        bool flag_2;

        if (compOperator_1(sn) == 1) flag_1 = data_1 > para_1(sn);
        else if (compOperator_1(sn) == 2) flag_1 = data_1 < para_1(sn);
        else if (compOperator_1(sn) == 3) flag_1 = data_1 >= para_1(sn);
        else if (compOperator_1(sn) == 4) flag_1 = data_1 <= para_1(sn);

        if (compOperator_2(sn) == 1) flag_2 = data_2 > para_2(sn);
        else if (compOperator_2(sn) == 2) flag_2 = data_2 < para_2(sn);
        else if (compOperator_2(sn) == 3) flag_2 = data_2 >= para_2(sn);
        else if (compOperator_2(sn) == 4) flag_2 = data_2 <= para_2(sn);

        if (logOperator(sn) == 1) return flag_1 && flag_2;
        else if (logOperator(sn) == 2) return flag_1 || flag_2;
        else if (logOperator(sn) == 3) return flag_1;
        else if (logOperator(sn) == 4) return flag_2;
        else if (logOperator(sn) == 5) return flag_1 == flag_2;
        else if (logOperator(sn) == 6) return flag_1 != flag_2;
    }

    // ==================================

    function shortShareNumberOfFt(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn);
    }

    function parValueOfFt(bytes32 sn) internal pure returns (uint256) {
        return uint256(uint64(sn >> 144));
    }

    function paidParOfFt(bytes32 sn) internal pure returns (uint256) {
        return uint256(uint64(sn >> 80));
    }
}
