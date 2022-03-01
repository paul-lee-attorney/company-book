/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/BookOfDocuments.sol";
import "../common/BookOfTerms.sol";

import "../interfaces/IShareholdersAgreement.sol";

contract BookOfSHA is BookOfTerms, BookOfDocuments {
    bytes32 private _pointer;

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

        address[] memory terms = IShareholdersAgreement(body).getTerms();

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
        if (_pointer != 0) _snToDoc[_pointer].state = 3;
        // 设定SHA法律效力
        _pointer = _bodyToSN[body];
        _snToDoc[_pointer].state = 2;
        emit SetPointer(_pointer, body);
    }

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (bytes32) {
        return _pointer;
    }

    function getTheOne() external view returns (address) {
        return _snToDoc[_pointer].body;
    }
}
