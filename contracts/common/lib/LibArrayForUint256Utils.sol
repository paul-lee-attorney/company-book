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

import "./SafeMath.sol";

library LibArrayForUint256Utils {
    /**
     * @dev Searches a sortd uint array and returns the first element index that
     * match the key value, Time complexity O(log n)
     *
     * @param array is expected to be sorted in ascending order
     * @param key is element
     *
     * @return if matches key in the array return true,else return false
     * @return the first element index that match the key value,if not exist,return 0
     */
    // function binarySearch(uint[] storage array, uint key)
    //     internal
    //     view
    //     returns (bool, uint)
    // {
    //     if (array.length == 0) {
    //         return (false, 0);
    //     }

    //     uint low = 0;
    //     uint high = array.length - 1;

    //     while (low <= high) {
    //         uint mid = SafeMath.average(low, high);
    //         if (array[mid] == key) {
    //             return (true, mid);
    //         } else if (array[mid] > key) {
    //             high = mid - 1;
    //         } else {
    //             low = mid + 1;
    //         }
    //     }

    //     return (false, 0);
    // }

    function firstIndexOf(uint[] storage array, uint key)
        internal
        view
        returns (bool, uint)
    {
        if (array.length == 0) {
            return (false, 0);
        }

        for (uint i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    // function reverse(uint[] storage array) internal {
    //     uint temp;
    //     for (uint i = 0; i < array.length / 2; i++) {
    //         temp = array[i];
    //         array[i] = array[array.length - 1 - i];
    //         array[array.length - 1 - i] = temp;
    //     }
    // }

    // function equals(uint[] storage a, uint[] storage b)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     if (a.length != b.length) {
    //         return false;
    //     }
    //     for (uint i = 0; i < a.length; i++) {
    //         if (a[i] != b[i]) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    function removeByIndex(uint[] storage array, uint index) internal {
        require(index < array.length, "ArrayForUint256: index out of bounds");

        while (index < array.length - 1) {
            array[index] = array[index + 1];
            index++;
        }
        array.length--;
    }

    function removeByValue(uint[] storage array, uint value) internal {
        uint index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (isIn) {
            removeByIndex(array, index);
        }
    }

    function addValue(uint[] storage array, uint value) internal {
        uint index;
        bool isIn;
        (isIn, index) = firstIndexOf(array, value);
        if (!isIn) {
            array.push(value);
        }
    }

    // function extend(uint[] storage a, uint[] storage b) internal {
    //     if (b.length != 0) {
    //         for (uint i = 0; i < b.length; i++) {
    //             a.push(b[i]);
    //         }
    //     }
    // }

    // function distinct(uint[] storage array)
    //     internal
    //     returns (uint length)
    // {
    //     bool contains;
    //     uint index;
    //     for (uint i = 0; i < array.length; i++) {
    //         contains = false;
    //         index = 0;
    //         uint j = i + 1;
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

    // function qsort(uint[] storage array) internal {
    //     qsort(array, 0, array.length - 1);
    // }

    // function qsort(
    //     uint[] storage array,
    //     uint begin,
    //     uint end
    // ) private {
    //     if (begin >= end || end == uint(-1)) return;
    //     uint pivot = array[end];

    //     uint store = begin;
    //     uint i = begin;
    //     for (; i < end; i++) {
    //         if (array[i] < pivot) {
    //             if (i > store) {
    //                 uint tmp = array[i];
    //                 array[i] = array[store];
    //                 array[store] = tmp;
    //             }
    //             store++;
    //         }
    //     }

    //     array[end] = array[store];
    //     array[store] = pivot;

    //     qsort(array, begin, store - 1);
    //     qsort(array, store + 1, end);
    // }

    // function max(uint[] storage array)
    //     internal
    //     view
    //     returns (uint maxValue, uint maxIndex)
    // {
    //     maxValue = array[0];
    //     maxIndex = 0;
    //     for (uint i = 0; i < array.length; i++) {
    //         if (array[i] > maxValue) {
    //             maxValue = array[i];
    //             maxIndex = i;
    //         }
    //     }
    // }

    // function min(uint[] storage array)
    //     internal
    //     view
    //     returns (uint minValue, uint minIndex)
    // {
    //     minValue = array[0];
    //     minIndex = 0;
    //     for (uint i = 0; i < array.length; i++) {
    //         if (array[i] < minValue) {
    //             minValue = array[i];
    //             minIndex = i;
    //         }
    //     }
    // }
}
