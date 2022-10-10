// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library SNFactory {
    function bytesToBytes32(bytes memory input)
        internal
        pure
        returns (bytes32 output)
    {
        // for (uint256 i = 0; i < 32; i++) {
        //     output |= bytes32(input[i] & 0xff) >> (i * 8);
        // }

        assembly {
            output := mload(add(input, 0x20))
        }
    }

    function intToSN(
        bytes memory sn,
        uint8 pointer,
        uint256 input,
        uint256 len
    ) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < len; i++)
            sn[i + pointer] = bytes1(uint8(input >> ((len - 1 - i) * 8)));

        return sn;
    }

    function dateToSN(
        bytes memory sn,
        uint256 pointer,
        uint32 input
    ) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < 4; i++)
            sn[i + pointer] = bytes1(uint8(input >> ((3 - i) * 8)));

        return sn;
    }

    function acctToSN(
        bytes memory sn,
        uint256 pointer,
        uint40 input
    ) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < 5; i++)
            sn[i + pointer] = bytes1(uint8(input >> ((4 - i) * 8)));

        return sn;
    }

    function sequenceToSN(
        bytes memory sn,
        uint256 pointer,
        uint16 input
    ) internal pure returns (bytes memory) {
        sn[pointer] = bytes1(uint8(input >> 8));
        sn[pointer + 1] = bytes1(uint8(input));

        return sn;
    }

    function addrToSN(
        bytes memory sn,
        uint256 pointer,
        address acct
    ) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < 20; i++)
            sn[i + pointer] = bytes1(uint8(uint160(acct) >> ((19 - i) * 8)));

        return sn;
    }

    function boolToSN(
        bytes memory sn,
        uint256 pointer,
        bool input
    ) internal pure returns (bytes memory) {
        sn[pointer] = input ? bytes1(uint8(1)) : bytes1(uint8(0));

        return sn;
    }

    function bytes32ToSN(
        bytes memory sn,
        uint256 pointer,
        bytes32 input,
        uint256 inputStartPoint,
        uint256 len
    ) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < len; i++)
            sn[pointer + i] = input[inputStartPoint + i];

        return sn;
    }
}
