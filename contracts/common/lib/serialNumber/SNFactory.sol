pragma solidity ^0.4.24;

library SNFactory {
    function bytesToBytes32(bytes input)
        internal
        pure
        returns (bytes32 output)
    {
        assembly {
            output := mload(add(input, 0x20))
        }
    }

    function intToSN(
        bytes sn,
        uint8 pointer,
        uint256 input,
        uint8 len
    ) internal pure returns (bytes) {
        for (uint8 i = 0; i < len; i++)
            sn[i + pointer] = bytes1(uint8(input >> ((len - 1 - i) * 8)));

        return sn;
    }

    function dateToSN(
        bytes sn,
        uint8 pointer,
        uint32 input
    ) internal pure returns (bytes) {
        for (uint8 i = 0; i < 4; i++)
            sn[i + pointer] = bytes1(input << (i * 8));

        return sn;
    }

    function sequenceToSN(
        bytes sn,
        uint8 pointer,
        uint16 input
    ) internal pure returns (bytes) {
        sn[pointer] = bytes1(input);
        sn[pointer + 1] = bytes1(uint8(input));

        return sn;
    }

    function addrToSN(
        bytes sn,
        uint8 pointer,
        address acct
    ) internal pure returns (bytes) {
        for (uint8 i = 0; i < 20; i++)
            sn[i + pointer] = bytes1(bytes20(acct) << (i * 8));

        return sn;
    }

    function shortToSN(
        bytes sn,
        uint8 pointer,
        bytes6 input
    ) internal pure returns (bytes) {
        for (uint8 i = 0; i < 6; i++) sn[pointer + i] = input[i];

        return sn;
    }

    function boolToSN(
        bytes sn,
        uint8 pointer,
        bool input
    ) internal pure returns (bytes) {
        sn[pointer] = input ? bytes1(1) : bytes1(0);

        return sn;
    }

    function bytes32ToSN(
        bytes sn,
        uint8 pointer,
        bytes32 input,
        uint8 inputStartPoint,
        uint8 len
    ) internal pure returns (bytes) {
        for (uint8 i = 0; i < len; i++)
            sn[pointer + i] = input[inputStartPoint + i];

        return sn;
    }
}
