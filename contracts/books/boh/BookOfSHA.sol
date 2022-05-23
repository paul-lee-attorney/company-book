/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/components/BookOfDocuments.sol";

import "./interfaces/IShareholdersAgreement.sol";

contract BookOfSHA is BookOfDocuments {
    address public pointer;

    // constructor(
    //     string _bookName,
    //     uint32 _owner,
    //     uint32 _bookeeper
    // ) public BookOfDocuments(_bookName, _admin, _bookeeper, _rc) {}

    //##############
    //##  Event   ##
    //##############

    event ChangePointer(address indexed pointer, address indexed body);

    //##################
    //##    写接口    ##
    //##################

    function submitSHA(
        address body,
        uint32 submitDate,
        bytes32 docHash,
        uint32 submitter
    ) external onlyKeeper {
        submitDoc(body, submitDate, docHash, submitter);

        // address[] memory terms = IShareholdersAgreement(body).terms();

        // for (uint256 i = 0; i < terms.length; i++) {
        //     _addTermToRegistry(terms[i]);
        // }
    }

    function changePointer(address body)
        external
        onlyKeeper
        onlyRegistered(body)
        onlyForSubmitted(body)
    {
        if (pointer != address(0)) _docs[pointer].state = 3;

        _docs[body].state = 2;
        emit ChangePointer(pointer, body);

        pointer = body;
    }
}
