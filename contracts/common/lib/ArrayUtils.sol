/*
 * Copyright 2014-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * */

pragma solidity ^0.4.24;

library ArrayUtils {
    // ======== uint256 ========

    function firstIndexOf(uint256[] storage array, uint256 key)
        internal
        view
        returns (bool, uint256)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "ArrayForUint256: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(uint256[] storage array, uint256 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(uint256[] storage array, uint256 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }

    // ======== uint8 ========

    function firstIndexOf(uint8[] storage array, uint8 key)
        internal
        view
        returns (bool, uint256)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(uint8[] storage array, uint256 index) internal {
        require(index < array.length, "ArrayForUint8: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(uint8[] storage array, uint8 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(uint8[] storage array, uint8 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }

    // ======== uint16 ========

    function firstIndexOf(uint16[] storage array, uint16 key)
        internal
        view
        returns (bool, uint256)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(uint16[] storage array, uint256 index) internal {
        require(index < array.length, "ArrayForUint8: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(uint16[] storage array, uint16 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(uint16[] storage array, uint16 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }

    // ======== uint32 ========

    function firstIndexOf(uint32[] storage array, uint32 key)
        internal
        view
        returns (bool, uint256)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(uint32[] storage array, uint256 index) internal {
        require(index < array.length, "ArrayForUint8: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(uint32[] storage array, uint32 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(uint32[] storage array, uint32 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }

    // ======== address ========

    function firstIndexOf(address[] storage array, address key)
        internal
        view
        returns (bool, uint256)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(address[] storage array, uint256 index) internal {
        require(index < array.length, "ArrayForaddress: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(address[] storage array, address value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(address[] storage array, address value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }

    function combine(uint32[] arrA, uint32[] arrB)
        internal
        pure
        returns (uint32[])
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        uint256 i;

        uint32[] memory arrC = new uint32[](lenA + lenB);

        for (i = 0; i < lenA; i++) arrC[i] = arrA[i];
        for (i = 0; i < lenB; i++) arrC[lenA + i] = arrB[i];

        return arrC;
    }

    function minus(uint32[] arrA, uint32[] arrB) internal returns (uint32[]) {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        uint32[] storage arrC;

        for (uint256 i = 0; i < lenA; i++) {
            bool flag = false;
            for (uint256 j = 0; j < lenB; j++) {
                if (arrB[j] == arrA[i]) {
                    flag = true;
                    break;
                }
            }
            if (!flag) arrC.push(arrA[i]);
        }

        return arrC;
    }

    function fullyCoveredBy(uint32[] arrA, uint32[] arrB)
        internal
        pure
        returns (bool)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        bool flag;

        for (uint256 i = 0; i < lenA; i++) {
            flag = false;
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

    // ======== bytes32 ========

    function firstIndexOf(bytes32[] storage array, bytes32 key)
        internal
        view
        returns (bool, uint256)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeByIndex(bytes32[] storage array, uint256 index) internal {
        require(index < array.length, "ArrayForbytes32: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(bytes32[] storage array, bytes32 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(bytes32[] storage array, bytes32 value) internal {
        uint256 index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }
}
