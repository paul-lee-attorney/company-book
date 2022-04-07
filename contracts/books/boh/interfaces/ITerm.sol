/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface ITerm {
    function isTriggered(address ia, uint8 snOfDeal)
        external
        view
        returns (bool);

    function isExempted(address ia, uint8 snOfDeal)
        external
        view
        returns (bool);
}
