/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library ArrayUtils {
    function combine(uint40[] arrA, uint40[] arrB)
        internal
        pure
        returns (uint40[])
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        uint256 i;

        uint40[] memory arrC = new uint40[](lenA + lenB);

        for (i = 0; i < lenA; i++) arrC[i] = arrA[i];
        for (i = 0; i < lenB; i++) arrC[lenA + i] = arrB[i];

        return arrC;
    }

    function minus(uint40[] arrA, uint40[] arrB)
        internal
        pure
        returns (uint40[])
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        uint40[] memory arrC = new uint40[](lenA);

        uint256 pointer;

        while (lenA > 0) {
            bool flag = false;
            lenB = arrB.length;
            while (lenB > 0) {
                if (arrB[lenB - 1] == arrA[lenA - 1]) {
                    flag = true;
                    break;
                }
                lenB--;
            }

            if (!flag) {
                arrC[pointer] = arrA[lenA - 1];
                pointer++;
            }

            lenA--;
        }

        uint40[] memory output = new uint40[](pointer);
        lenA = 0;

        while (lenA < pointer) {
            output[lenA] = arrC[lenA];
            lenA++;
        }

        return output;
    }

    function fullyCoveredBy(uint40[] arrA, uint40[] arrB)
        internal
        pure
        returns (bool)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        for (uint256 i = 0; i < lenA; i++) {
            bool flag;
            for (uint256 j = 0; j < lenB; j++) {
                if (arrB[j] == arrA[i]) {
                    flag = true;
                    break;
                }
            }
            if (!flag) return false;
        }

        return true;
    }
}
