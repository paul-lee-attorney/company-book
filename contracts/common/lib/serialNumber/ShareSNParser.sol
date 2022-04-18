pragma solidity ^0.4.24;

library ShareSNParser {
    function class(bytes32 shareNumber) internal pure returns (uint8) {
        return uint8(shareNumber[0]);
    }

    function sequence(bytes32 shareNumber) internal pure returns (uint16) {
        return uint16(bytes2(shareNumber << 8));
    }

    function issueDate(bytes32 shareNumber) internal pure returns (uint256) {
        return uint256(bytes4(shareNumber << 24));
    }

    function short(bytes32 shareNumber) internal pure returns (bytes6) {
        return bytes6(shareNumber << 8);
    }

    function shareholder(bytes32 shareNumber) internal pure returns (address) {
        return address(bytes20(shareNumber << 56));
    }

    function shortToSN(bytes32 ssn, bytes32[] memory sharesList)
        internal
        pure
        returns (bytes32)
    {
        uint256 len = sharesList.length;
        for (uint256 i = 0; i < len; i++)
            if (bytes6(ssn) == bytes6(sharesList[i] << 8)) return sharesList[i];

        return bytes32(0);
    }

    function preSN(bytes32 shareNumber, bytes32[] memory sharesList)
        internal
        pure
        returns (bytes32)
    {
        bytes5 ssn = bytes5(shareNumber << 216);
        uint256 len = sharesList.length;
        for (uint256 i = 0; i < len; i++)
            if (ssn == bytes5(sharesList[i] << 8)) return sharesList[i];
        return bytes32(0);
    }
}
