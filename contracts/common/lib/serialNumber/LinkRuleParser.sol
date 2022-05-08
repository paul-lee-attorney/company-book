/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library LinkRuleParser {
    function dragerOfLink(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn));
    }

    function triggerTypeOfLink(bytes32 sn) internal pure returns (uint8) {
        return uint8(bytes1(sn << 16));
    }

    function basedOnParOfLink(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[3]) == 1;
    }

    function thresholdOfLink(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 32));
    }

    function proRataOfLink(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[5]) == 1;
    }

    function unitPriceOfLink(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 72));
    }

    function roeOfLink(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes4(sn << 104));
    }
}
