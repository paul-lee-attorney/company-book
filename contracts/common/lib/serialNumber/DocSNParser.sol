/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library DocSNParser {
    function typeOfDoc(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function sequenceOfDoc(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 8));
    }

    function createDateOfDoc(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 24));
    }

    function shortOfDoc(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn << 8);
    }

    function creatorOfDoc(bytes32 sn) internal pure returns (address) {
        return address(bytes20(sn << 56));
    }

    function addrSuffixOfDoc(bytes32 sn) internal pure returns (bytes5) {
        return bytes5(sn << 216);
    }
}
