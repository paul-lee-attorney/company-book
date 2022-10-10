// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library ArrowChain {
    struct Mark {
        uint40 key;
        uint64 value;
        uint40 prev;
        uint40 next;
    }

    struct MarkChain {
        mapping(uint256 => Mark) marks;
    }

/*
    Mark[0] {
        key: qtyOfMarks;
        value: (pending);
        prev: tail;
        next: head;
    }
*/

    function addMark(
        MarkChain storage c,
        uint40 key,
        uint64 value
    ) internal returns (bool flag) {

        if (key > 0 && c.marks[key].key == 0) {
            Mark storage m = c.marks[key];

            m.key = key;
            m.value = value;

            _insertToChain(c, m);

            c.marks[0].key++;

            flag = true;
        }
    }

    function _insertToChain(MarkChain storage c, Mark storage m) private {
        uint40 cur = c.marks[0].prev;

        if (cur == 0) {
            c.marks[0].prev = m.key;
            c.marks[0].next = m.key;
        } else {
            while (cur > 0) {
                if (c.marks[cur].value <= m.value) break;
                else cur = c.marks[cur].prev;
            }

            m.next = c.marks[cur].next;
            c.marks[m.next].prev = m.key;

            m.prev = cur;
            c.marks[cur].next = m.key;
        }
    }

    function updateMark(
        MarkChain storage c,
        uint40 key,
        uint64 value
    ) internal returns (bool flag) {
        Mark storage m = c.marks[key];

        if (key > 0 && m.key == key) {
            m.value = value;
            _unlinkMark(c, m);
            _insertToChain(c, m);
            flag = true;
        } 
    }

    function _unlinkMark(MarkChain storage c, Mark storage m) private {
        c.marks[m.next].prev = m.prev;
        c.marks[m.prev].next = m.next;
    }

    function removeMark(MarkChain storage c, uint40 key)
        internal
        returns (bool flag)
    {
        Mark storage m = c.marks[key];

        if (key > 0 && m.key == key) {
            _unlinkMark(c, m);
            delete c.marks[key];
            flag = true;
        }
    }

    function contains(MarkChain storage c, uint40 key)
        internal
        view
        returns (bool flag)
    {
        if (key > 0 && c.marks[key].key == key) flag = true;
    }

    function markedValue(MarkChain storage c, uint40 key)
        internal
        view
        returns (uint64 value)
    {
        if (contains(c, key)) value = c.marks[key].value;
    }

    function topValue(MarkChain storage c) internal view returns (uint64) {
        return c.marks[c.marks[0].prev].value;
    }

    function topKey(MarkChain storage c) internal view returns (uint40) {
        return c.marks[c.marks[0].prev].key;
    }

    function prevKey(MarkChain storage c, uint40 cur)
        internal
        view
        returns (uint40)
    {
        return c.marks[cur].prev;
    }

    function nextKey(MarkChain storage c, uint40 cur)
        internal
        view
        returns (uint40)
    {
        return c.marks[cur].next;
    }

    function getChain(MarkChain storage c)
        internal
        view
        returns (Mark[] memory)
    {
        uint len = c.marks[0].key; 
        Mark[] memory chain = new Mark[](len + 1);

        uint cur = 0;
        uint i = 0;

        while (i <= len) {
            Mark storage m = c.marks[cur];

            chain[i] = Mark(m.key, m.value, m.prev, m.next);

            cur = m.next;
            i++;            
        }

        return chain;
    }

}