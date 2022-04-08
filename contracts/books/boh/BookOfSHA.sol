/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/component/BookOfDocuments.sol";
import "../common/component/BookOfTerms.sol";

import "../common/interfaces/IShareholdersAgreement.sol";

contract BookOfSHA is BookOfTerms, BookOfDocuments {
    bytes32 public pointer;

    constructor(
        string _bookName,
        address _admin,
        address _bookeeper
    ) public BookOfDocuments(_bookName, _admin, _bookeeper) {}

    //##############
    //##  Event   ##
    //##############

    event SetPointer(bytes32 indexed pointer, address body);

    //##################
    //##    写接口    ##
    //##################

    function submitSHA(address body, bytes32 docHash) external onlyBookeeper {
        submitDoc(body, docHash);

        address[] memory terms = IShareholdersAgreement(body).terms();

        for (uint256 i = 0; i < terms.length; i++) {
            _addTermToRegistry(terms[i]);
        }
    }

    function setPointer(address body)
        external
        onlyBookeeper
        onlyRegistered(body)
        onlyForSubmitted(body)
    {
        if (pointer != 0) _snToDoc[pointer].state = 3;
        // 设定SHA法律效力
        pointer = bodyToSN[body];
        _snToDoc[pointer].state = 2;
        emit SetPointer(pointer, body);
    }

    //##################
    //##    读接口    ##
    //##################

    function getTheOne() external view returns (address) {
        return _snToDoc[pointer].body;
    }
}
