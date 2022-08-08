/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IBookOfSHA.sol";

import "../../common/components/DocumentsRepo.sol";

contract BookOfSHA is IBookOfSHA, DocumentsRepo {
    address private _pointer;

    // constructor(
    //     string _bookName,
    //     uint40 _owner,
    //     uint40 _bookeeper
    // ) public DocumentsRepo(_bookName, _admin, _bookeeper, _rc) {}

    //##################
    //##    写接口    ##
    //##################

    function changePointer(address body, uint40 caller)
        external
        onlyManager(1)
        onlyRegistered(body)
    {
        if (_pointer != address(0)) pushToNextState(_pointer, caller);

        pushToNextState(body, caller);

        _pointer = body;

        emit ChangePointer(_pointer, body);
    }

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address) {
        return _pointer;
    }
}
