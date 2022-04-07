/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

contract BookOfTerms {
    // body => bool
    mapping(address => bool) private _registeredTerms;

    event AddTermToRegistry(address indexed term);

    function _addTermToRegistry(address term) internal {
        _registeredTerms[term] = true;
        emit AddTermToRegistry(term);
    }

    function isRegisteredTerm(address term) external view returns (bool) {
        return _registeredTerms[term];
    }
}
