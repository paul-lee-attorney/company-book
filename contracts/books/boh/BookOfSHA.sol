/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/components/BookOfDocuments.sol";

import "./interfaces/IShareholdersAgreement.sol";

contract BookOfSHA is BookOfDocuments {
    enum BOHStates {
        ZeroPoint,
        Created,
        Submitted,
        Effective,
        Revoked
    }

    address public pointer;

    // constructor(
    //     string _bookName,
    //     uint40 _owner,
    //     uint40 _bookeeper
    // ) public BookOfDocuments(_bookName, _admin, _bookeeper, _rc) {}

    //##############
    //##  Event   ##
    //##############

    event ChangePointer(address indexed pointer, address indexed body);

    //##################
    //##    写接口    ##
    //##################

    function changePointer(
        address body,
        uint40 caller,
        uint32 sigDate
    ) external onlyDirectKeeper onlyRegistered(body) {
        if (pointer != address(0)) pushToNextState(pointer, sigDate, caller);

        pushToNextState(body, sigDate, caller);

        pointer = body;

        emit ChangePointer(pointer, body);
    }
}
