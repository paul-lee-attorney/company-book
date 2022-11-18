// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/SigsRepo.sol";

import "../access/AccessControl.sol";

import "./ISigPage.sol";

contract SigPage is ISigPage, AccessControl {
    using SigsRepo for SigsRepo.Page;

    SigsRepo.Page private _sigPage;

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(uint32 deadline)
        external
        onlyAttorney
    {
        _sigPage.setSigDeadline(deadline);
        emit SetSigDeadline(deadline);
    }

    function setClosingDeadline(uint32 deadline)
        external
        onlyAttorney
    {
        _sigPage.setClosingDeadline(deadline);
        emit SetClosingDeadline(deadline);
    }

    function signDoc(uint40 caller, bytes32 sigHash) external onlyDK onlyFinalized {
        signDeal(0, caller, sigHash);
    }

    function acceptDoc(bytes32 sigHash, uint40 caller) external onlyDK {
        require(_sigPage.established(), "SP.acceptDoc: Doc not established");
        signDeal(0, caller, sigHash);
    }

    function addBlank(uint40 acct, uint16 ssn) public {
        if (!finalized())
            require(
                hasRole(ATTORNEYS, _msgSender()),
                "only Attorney may add party to a pending DOC"
            );
        else
            require(
                _gk.isKeeper(msg.sender),
                "only DK may add party to an established DOC"
            );

        if (_sigPage.addBlank(acct, ssn))
            emit AddBlank(acct, ssn);
    }

    function removeBlank(uint40 acct, uint16 ssn)
        public
        onlyAttorney
    {
        if (_sigPage.removeBlank(acct, ssn))
            emit RemoveBlank(acct, ssn);  
    }

    function addParty(uint40 acct) external onlyAttorney {
        addBlank(acct, 0);
    }

    function signDeal(
        uint16 ssn,
        uint40 caller,
        bytes32 sigHash
    ) public onlyDK {
        _sigPage.signDeal(caller, ssn, sigHash);
        emit SignDeal(caller, ssn, sigHash);
    }

    //####################
    //##    查询接口    ##
    //####################

    function established() external view returns (bool) {
        return _sigPage.established();
    }

    function sigDeadline() external view returns (uint32) {
        return _sigPage.sigDeadline();
    }

    function closingDeadline() public view returns (uint32) {
        return _sigPage.closingDeadline();
    }

    function isParty(uint40 acct) external view returns (bool) {
        return _sigPage.isParty(acct);
    }

    function isInitSigner(uint40 acct) external view returns (bool) {
        return _sigPage.isInitSigner(acct);
    }

    function partiesOfDoc() external view returns (uint40[] memory) {
        return _sigPage.partiesOfDoc();
    }

    function qtyOfParties() external view returns (uint256) {
        return _sigPage.qtyOfParties();
    }

    function blankCounter() external view returns (uint16) {
        return _sigPage.blankCounterOfDoc();
    }

    function sigCounter() external view returns (uint16) {
        return _sigPage.sigCounter();
    }

    function sigOfDeal(uint40 acct, uint16 ssn)
        external view
        returns (
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        ) 
    {
        return _sigPage.sigOfDeal(acct, ssn);        
    }

    function sigDateOfDoc(uint40 acct)
        external
        view
        returns (uint32 sigDate)
    {
        ( , sigDate, ) = _sigPage.sigOfDeal(acct, 0);
    }

    function sigHashOfDoc(uint40 acct)
        external
        view
        returns (bytes32 sigHash)
    {
        ( , , sigHash) = _sigPage.sigOfDeal(acct, 0);
    }

    function dealSigVerify(
        uint40 acct,
        uint16 ssn,
        string memory src
    ) external view returns (bool) {
        return _sigPage.dealSigVerify(acct, ssn, src);
    }
}
