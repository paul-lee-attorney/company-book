pragma solidity ^0.4.24;

library DealSNParser {
    function classOfDeal(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function typeOfDeal(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[1]);
    }

    function sequenceOfDeal(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 16));
    }

    function buyerOfDeal(bytes32 sn) internal pure returns (address) {
        return address(bytes20(sn << 32));
    }

    function shortShareNumberOfDeal(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn << 192);
    }

    function shortOfDeal(bytes32 sn) internal pure returns (bytes6) {
        return bytes6(sn << 16);
    }

    function shareNumberOfDeal(bytes32 sn, bytes32[] memory sharesList)
        internal
        pure
        returns (bytes32)
    {
        bytes6 ssn = bytes6(sn << 192);
        uint256 len = sharesList.length;
        for (uint256 i = 0; i < len; i++)
            if (ssn == bytes6(sharesList[i] << 8)) return sharesList[i];
    }

    function sellerOfDeal(bytes32 sn, bytes32[] memory sharesList)
        internal
        pure
        returns (address)
    {
        bytes6 ssn = bytes6(sn << 192);
        if (sn == bytes6(0)) return address(0);

        uint256 len = sharesList.length;

        for (uint256 i = 0; i < len; i++)
            if (ssn == bytes6(sharesList[i] << 8))
                return address(bytes20(sharesList[i] << 56));

        return address(0);
    }
}
