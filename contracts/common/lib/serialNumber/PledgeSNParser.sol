/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library PledgeSNParser {
    function shortOfShare(bytes32 sn) internal pure returns (bytes6) {
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

    function debtor(bytes32 sn) internal pure returns (address) {
        return address(uint160(sn));
    }

    function pledgor(bytes32 sn, bytes32[] memory sharesList)
        internal
        pure
        returns (address)
    {
        uint256 len = sharesList.length;
        for (uint256 i = 0; i < len; i++)
            if (bytes6(sharesList[i] << 8) == bytes6(sn))
                return address(bytes20(sharesList[i] << 56));

        return address(0);
    }
}
