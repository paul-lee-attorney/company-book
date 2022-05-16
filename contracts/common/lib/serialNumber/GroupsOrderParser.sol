/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library GroupsOrderParser {
    function addMemberOfGUO(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[0]) == 1;
    }

    function groupNoOfGUO(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 8));
    }

    function memberAddrOfGUO(bytes32 sn) internal pure returns (address) {
        return address(bytes20(sn << 24));
    }
}
