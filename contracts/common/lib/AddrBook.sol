/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";

library AddrBook {
    using ArrayUtils for address[];

    struct Book {
        mapping(address => bool) isIn;
        address[] chapters;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addChapter(Book storage book, address addr)
        internal
        returns (bool flag)
    {
        if (!book.isIn[addr]) {
            book.isIn[addr] = true;
            book.chapters.push(addr);
            flag = true;
        } else flag = false;
    }

    function removeChapter(Book storage book, address addr)
        internal
        returns (bool flag)
    {
        if (book.isIn[addr]) {
            book.isIn[addr] = false;
            book.chapters.removeByValue(addr);
            flag = true;
        } else flag = false;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isChapter(Book storage book, address addr)
        internal
        view
        returns (bool)
    {
        return book.isIn[addr];
    }

    function qtyOfChapters(Book storage book) internal view returns (uint256) {
        return book.chapters.length;
    }

    function getChapters(Book storage book) internal view returns (address[]) {
        return book.chapters;
    }
}
