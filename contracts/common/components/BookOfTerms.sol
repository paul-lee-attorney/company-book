/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

contract BookOfTerms {
    // body => bool
    mapping(address => bool) public isRegistered;

    event AddTermToRegistry(address indexed term);

    function _addTermToRegistry(address term) internal {
        isRegistered[term] = true;
        emit AddTermToRegistry(term);
    }
}
