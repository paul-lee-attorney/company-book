/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library Queue {
    struct UintQueue {
        uint256 _head;
        uint256 _tail;
        mapping(uint256 => uint256) _data;
    }

    function push(UintQueue storage que, uint256 value) internal {
        uint256 index = que._tail;
        que._data[index] = value;
        que._tail = index + 1;
    }

    function pop(UintQueue storage que) internal returns (uint256 value) {
        if (empty(que)) revert("empty que");
        uint256 index = que._head;
        value = que._data[index];
        delete que._data[index];
        que._head = index + 1;
    }

    function clear(UintQueue storage que) internal {
        que._head = 0;
        que._tail = 0;
    }

    function length(UintQueue storage que) internal view returns (uint256) {
        return que._tail - que._head;
    }

    function empty(UintQueue storage que) internal view returns (bool) {
        return que._tail <= que._head;
    }
}
