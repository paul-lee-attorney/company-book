pragma solidity ^0.4.24;

library DealSNParser {
    function sequenceOfDeal(bytes32 sn) internal pure returns (uint16 counter) {
        counter = uint16(bytes2(sn));
    }

    function typeOfDeal(bytes32 sn) internal pure returns (uint8 typeOfDeal) {
        typeOfDeal = uint8(sn[3]);
    }

    function classOfDeal(bytes32 sn) internal pure returns (uint8 class) {
        class = uint8(sn[9]);
    }

    function buyer(bytes32 sn) internal pure returns (address buyer) {
        buyer = address(bytes20(sn << 80));
    }

    function shareNumber(bytes32 sn, bytes32[] memory sharesList)
        internal
        pure
        returns (bytes32)
    {
        bytes6 ssn = bytes6(sn << 24);
        uint256 len = sharesList.length;

        for (uint256 i = 0; i < len; i++)
            if (ssn == bytes6(sharesList[i] << 8)) return sharesList[i];

        return bytes32(0);
    }

    function shortOfSeller(bytes32 sn) internal pure returns (bytes6 short) {
        short = bytes6(sn << 24);
    }

    function seller(bytes32 sn, bytes32[] memory sharesList)
        internal
        pure
        returns (address)
    {
        bytes6 ssn = bytes6(sn << 24);
        uint256 len = sharesList.length;

        for (uint256 i = 0; i < len; i++)
            if (ssn == bytes6(sharesList[i] << 8))
                return address(bytes20(sharesList[i] << 56));

        return address(0);
    }
}
