/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface ITerm {
    function isTriggered(address ia, uint16 snOfDeal)
        external
        view
        returns (bool);

    function isExempted(address ia, uint16 snOfDeal)
        external
        view
        returns (bool);
}
