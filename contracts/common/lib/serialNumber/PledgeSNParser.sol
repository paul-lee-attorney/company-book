/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library PledgeSNParser {
    function shortShareNumberOfPledge(bytes32 sn)
        internal
        pure
        returns (bytes6)
    {
        return bytes6(sn);
    }

    function sequenceOfPledge(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 48));
    }

    function createDateOfPledge(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 64));
    }

    function shortOfPledge(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn << 48);
    }

    function pledgor(bytes32 sn) internal pure returns (address) {
        return address(uint160(sn));
    }
}
