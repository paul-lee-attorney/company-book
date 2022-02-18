pragma solidity ^0.4.24;

library SerialNumFactory {
    function bytesToBytes32(bytes input) internal pure returns (bytes32 out) {
        assembly {
            out := mload(add(input, 0x20))
        }
    }

    function createSN(address body, uint8 docType)
        internal
        view
        returns (bytes32 sn)
    {
        // sn : 条款对象 序列号
        bytes memory _sn = new bytes(32);
        // 第 0 字节：docType - 文件内部分类(0-255)
        _sn[0] = bytes1(docType);

        // 第 1-4 字节: 创建时间戳（秒）
        uint32 createDate = uint32(now);
        uint8 i = 0;
        for (; i < 4; i++) {
            _sn[i + 1] = bytes1(uint8(createDate >> ((3 - i) * 8)));
        }

        // 第 5-24 字节：创建者地址
        uint160 creator = uint160(msg.sender);
        for (i = 0; i < 20; i++) {
            _sn[i + 5] = bytes1(uint8(creator >> ((19 - i) * 8)));
        }

        // 第 25-31 字节：文件合约地址（后56位）
        for (i = 0; i < 7; i++) {
            _sn[i + 25] = bytes1(uint8(uint160(body) >> ((6 - i) * 8)));
        }

        sn = bytesToBytes32(_sn);
    }

    // function toUint128(uint256 value) internal pure returns (uint128) {
    //     require(value < 2**128, "SafeCast: can not fit in 128 bits");
    //     return uint128(value);
    // }

    // function toUint8(uint256 value) internal pure returns (uint8) {
    //     require(value < 2**8, "SafeCast: can not fit in 8 bits");
    //     return uint8(value);
    // }

    // function uintToBytes(uint256 v) internal pure returns (bytes memory) {
    //     uint256 maxlength = 100;
    //     bytes memory reversed = new bytes(maxlength);
    //     uint256 i = 0;
    //     while (v != 0) {
    //         uint8 remainder = uint8(v % 10);
    //         v = v / 10;
    //         reversed[i % maxlength] = bytes1(48 + remainder);
    //         i++;
    //     }
    //     bytes memory s = new bytes(i + 1);
    //     for (uint256 j = 1; j <= i % maxlength; j++) {
    //         s[j - 1] = reversed[i - j];
    //     }
    //     return bytes(s);
    // }

    // function uintToString(uint256 v) internal pure returns (string memory) {
    //     return string(uintToBytes(v));
    // }

    // function bytesToInt(bytes memory b) internal pure returns (int256 result) {
    //     uint256 i = 0;
    //     uint256 tr = 0;
    //     result = 0;
    //     bool sign = false;
    //     if (b[i] == "-") {
    //         sign = true;
    //         i++;
    //     } else if (b[i] == "+") {
    //         i++;
    //     }
    //     while (uint8(b[b.length - tr - 1]) == 0x00) {
    //         tr++;
    //     }
    //     for (; i < b.length - tr; i++) {
    //         uint8 c = uint8(b[i]);
    //         if (c >= 48 && c <= 57) {
    //             result *= 10;
    //             result = result + int256(c - 48);
    //         }
    //     }
    //     if (sign) {
    //         result *= -1;
    //     }
    // }

    // function intToBytes(int256 v) internal pure returns (bytes memory) {
    //     uint256 maxlength = 100;
    //     bytes memory reversed = new bytes(maxlength);
    //     uint256 i = 0;
    //     uint256 x;
    //     if (v < 0) x = uint256(-v);
    //     else x = uint256(v);
    //     while (x != 0) {
    //         uint8 remainder = uint8(x % 10);
    //         x = x / 10;
    //         reversed[i % maxlength] = bytes1(48 + remainder);
    //         i++;
    //     }
    //     if (v < 0) reversed[(i++) % maxlength] = "-";
    //     bytes memory s = new bytes(i + 1);
    //     for (uint256 j = 1; j <= i % maxlength; j++) {
    //         s[j - 1] = reversed[i - j];
    //     }
    //     return bytes(s);
    // }
}
