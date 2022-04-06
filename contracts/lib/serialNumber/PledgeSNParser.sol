/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

library PledgeSNParser {
    function shortOfShareNumber(bytes32 sn)
        internal
        pure
        returns (bytes6 short)
    {
        short = bytes6(sn);
    }

    function sequenceOfPledge(bytes32 sn)
        internal
        pure
        returns (uint16 sequence)
    {
        sequence = uint16(bytes2(sn << 48));
    }

    function createDateOfPledge(bytes32 sn)
        internal
        pure
        returns (uint256 createDate)
    {
        createDate = uint256(bytes4(sn << 64));
    }

    function shortOfPledge(bytes32 sn) internal pure returns (bytes6 short) {
        short = bytes6(sn << 48);
    }

    function creditor(bytes32 sn) internal pure returns (address creditor) {
        creditor = address(uint160(sn));
    }

    function pledgor(bytes32 sn, bytes32[] memory sharesList)
        internal
        pure
        returns (address pledgor)
    {
        uint256 len = sharesList;
        for (uint256 i = 0; i < len; i++) {
            if (bytes6(sharesList[i] << 8) == bytes6(sn)) {
                pledgor = address(bytes20(sharesList[i] << 56));
                break;
            }
        }
    }
}
