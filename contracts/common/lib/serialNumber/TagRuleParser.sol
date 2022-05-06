/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library TagRuleParser {
    function dragerOfTag(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn));
    }

    function triggerTypeOfTag(bytes32 sn) internal pure returns (uint8) {
        return uint8(bytes1(sn << 16));
    }

    function basedOnParOfTag(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[3]) == 1;
    }

    function thresholdOfTag(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 32));
    }

    function proRataOfTag(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[5]) == 1;
    }
}
