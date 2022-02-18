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

library LibArrayFrUint8Utils {
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

    // function reverse(uint8[] storage array) internal {
    //     uint8 temp;
    //     for (uint256 i = 0; i < array.length / 2; i++) {
    //         temp = array[i];
    //         array[i] = array[array.length - 1 - i];
    //         array[array.length - 1 - i] = temp;
    //     }
    // }

    // function equals(uint8[] storage a, uint8[] storage b)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     if (a.length != b.length) {
    //         return false;
    //     }
    //     for (uint256 i = 0; i < a.length; i++) {
    //         if (a[i] != b[i]) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

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

    // function extend(uint8[] storage a, uint8[] storage b) internal {
    //     if (b.length != 0) {
    //         for (uint256 i = 0; i < b.length; i++) {
    //             a.push(b[i]);
    //         }
    //     }
    // }

    // function distinct(uint8[] storage array) internal returns (uint256 length) {
    //     bool contains;
    //     uint256 index;
    //     for (uint256 i = 0; i < array.length; i++) {
    //         contains = false;
    //         index = 0;
    //         uint256 j = i + 1;
    //         for (; j < array.length; j++) {
    //             if (array[j] == array[i]) {
    //                 contains = true;
    //                 index = i;
    //                 break;
    //             }
    //         }
    //         if (contains) {
    //             for (j = index; j < array.length - 1; j++) {
    //                 array[j] = array[j + 1];
    //             }
    //             array.length--;
    //             i--;
    //         }
    //     }
    //     length = array.length;
    // }

    // function qsort(uint8[] storage array) internal {
    //     qsort(array, 0, array.length - 1);
    // }

    // function qsort(
    //     uint8[] storage array,
    //     uint256 begin,
    //     uint256 end
    // ) private {
    //     if (begin >= end || end == uint256(-1)) return;
    //     uint8 pivot = array[end];

    //     uint256 store = begin;
    //     uint256 i = begin;
    //     for (; i < end; i++) {
    //         if (array[i] < pivot) {
    //             uint8 tmp = array[i];
    //             array[i] = array[store];
    //             array[store] = tmp;
    //             store++;
    //         }
    //     }

    //     array[end] = array[store];
    //     array[store] = pivot;

    //     qsort(array, begin, store - 1);
    //     qsort(array, store + 1, end);
    // }

    // function max(uint8[] storage array)
    //     internal
    //     view
    //     returns (uint8 maxValue, uint256 maxIndex)
    // {
    //     maxValue = array[0];
    //     maxIndex = 0;
    //     for (uint256 i = 0; i < array.length; i++) {
    //         if (array[i] > maxValue) {
    //             maxValue = array[i];
    //             maxIndex = i;
    //         }
    //     }
    // }

    // function min(uint8[] storage array)
    //     internal
    //     view
    //     returns (uint8 minValue, uint256 minIndex)
    // {
    //     minValue = array[0];
    //     minIndex = 0;
    //     for (uint256 i = 0; i < array.length; i++) {
    //         if (array[i] < minValue) {
    //             minValue = array[i];
    //             minIndex = i;
    //         }
    //     }
    // }
}
