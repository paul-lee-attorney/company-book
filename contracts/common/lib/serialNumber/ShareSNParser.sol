pragma solidity ^0.4.24;

library ShareSNParser {
    function class(bytes32 shareNumber) internal pure returns (uint8 class) {
        class = uint8(shareNumber[0]);
    }

    function sequence(bytes32 shareNumber) internal pure returns (uint16 sn) {
        sn = uint16(bytes2(shareNumber << 8));
    }

    function issueDate(bytes32 shareNumber)
        internal
        pure
        returns (uint256 issueDate)
    {
        issueDate = uint256(bytes4(shareNumber << 24));
    }

    function short(bytes32 shareNumber) internal pure returns (bytes6 short) {
        short = bytes6(shareNumber << 8);
    }

    function shortToSN(bytes32 short, bytes32[] memory sharesList)
        internal
        pure
        returns (bytes32 sn)
    {
        uint256 len = sharesList.length;
        for (uint256 i = 0; i < len; i++) {
            if (bytes6(short) == bytes6(sharesList[i] << 8)) {
                sn = sharesList[i];
                break;
            }
        }
    }

    function preSN(bytes32 shareNumber, bytes32[] memory sharesList)
        internal
        pure
        returns (bytes32 sn)
    {
        bytes5 short = bytes5(shareNumber << 216);
        uint256 len = sharesList.length;
        for (uint256 i = 0; i < len; i++) {
            if (short == bytes5(sharesList[i] << 8)) {
                sn = sharesList[i];
                break;
            }
        }
    }

    function shareholder(bytes32 shareNumber)
        internal
        pure
        returns (address shareholder)
    {
        shareholder = address(bytes20(shareNumber << 56));
    }

    function insertToQue(bytes32 sn, bytes32[] storage que) internal {
        uint256 len = que.length;
        que.push(sn);

        while (len > 0) {
            if (que[len - 1] <= que[len]) break;
            (que[len - 1], que[len]) = (que[len], que[len - 1]);
            len--;
        }
    }
}
