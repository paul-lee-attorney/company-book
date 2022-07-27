/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/IInvestmentAgreement.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOPSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/EnumsRepo.sol";
import "../common/lib/SNParser.sol";
import "../common/access/AccessControl.sol";

// import "../common/ruting/IBookSetting.sol";
import "../common/access/IAccessControl.sol";
import "../common/components/ISigPage.sol";

import "./IBOOKeeper.sol";

contract BOOKeeper is
    IBOOKeeper,
    IBookSetting,
    BOASetting,
    SHASetting,
    BOMSetting,
    BOPSetting,
    BOOSetting,
    BOSSetting,
    AccessControl
{
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(bytes32 sn, uint40 caller) {
        (, uint40 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
        require(caller == rightholder, "NOT rightholder");
        _;
    }

    modifier onlySeller(bytes32 sn, uint40 caller) {
        if (sn.typeOfOpt() > 0) {
            (, uint40 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(caller == rightholder, "msgSender NOT rightholder");
        } else
            require(
                _boo.isObligor(sn.shortOfOpt(), caller),
                "msgSender NOT seller"
            );
        _;
    }

    modifier onlyBuyer(bytes32 sn, uint40 caller) {
        if (sn.typeOfOpt() > 0)
            require(
                _boo.isObligor(sn.shortOfOpt(), caller),
                "caller NOT obligor"
            );
        else {
            (, uint40 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(caller == rightholder, "caller NOT rightholder");
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function setBooks(address[8] books) external onlyDirectKeeper {
        _setBOA(books[uint8(EnumsRepo.NameOfBook.BOA)]);
        _setBOH(books[uint8(EnumsRepo.NameOfBook.BOH)]);
        _setBOM(books[uint8(EnumsRepo.NameOfBook.BOM)]);
        _setBOP(books[uint8(EnumsRepo.NameOfBook.BOP)]);
        _setBOO(books[uint8(EnumsRepo.NameOfBook.BOO)]);
        _setBOS(books[uint8(EnumsRepo.NameOfBook.BOS)]);
    }

    function createOption(
        uint8 typeOfOpt,
        uint40 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate,
        uint64 parValue,
        uint64 paidPar,
        uint40 caller
    ) external onlyDirectKeeper {
        _boo.createOption(
            typeOfOpt,
            rightholder,
            caller,
            triggerDate,
            exerciseDays,
            closingDays,
            rate,
            parValue,
            paidPar
        );
    }

    function joinOptionAsObligor(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
    {
        _boo.addObligorIntoOpt(sn.shortOfOpt(), caller);
    }

    function releaseObligorFromOption(
        bytes32 sn,
        uint40 obligor,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _boo.removeObligorFromOpt(sn.shortOfOpt(), obligor);
    }

    function execOption(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
        onlyRightholder(sn, caller)
    {
        _boo.execOption(sn.shortOfOpt());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.addFuture(sn.shortOfOpt(), shareNumber, paidPar, paidPar);
    }

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _boo.removeFuture(sn.shortOfOpt(), ft);
        _bos.increaseCleanPar(ft.shortShareNumberOfFt(), ft.paidParOfFt());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external onlyDirectKeeper onlySeller(sn, caller) {
        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.requestPledge(sn.shortOfOpt(), shareNumber, paidPar);
    }

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint40 caller
    ) external onlyDirectKeeper onlySeller(sn, caller) {
        _boo.lockOption(sn.shortOfOpt(), hashLock);
    }

    function _recoverCleanPar(bytes32[] plds) private {
        uint256 len = plds.length;

        while (len > 0) {
            _bos.increaseCleanPar(
                plds[len - 1].shortShareNumberOfFt(),
                plds[len - 1].paidParOfFt()
            );
            len--;
        }
    }

    function closeOption(
        bytes32 sn,
        string hashKey,
        // uint32 closingDate,
        uint40 caller
    ) external onlyDirectKeeper onlyBuyer(sn, caller) {
        uint32 price = sn.rateOfOpt();

        _boo.closeOption(sn.shortOfOpt(), hashKey);

        bytes32[] memory fts = _boo.futures(sn.shortOfOpt());

        _recoverCleanPar(fts);

        for (uint256 i = 0; i < fts.length; i++) {
            _bos.transferShare(
                fts[i].shortShareNumberOfFt(),
                fts[i].parValueOfFt(),
                fts[i].paidParOfFt(),
                caller,
                price
            );
        }

        _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function revokeOption(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
        onlyRightholder(sn, caller)
    {
        _boo.revokeOption(sn.shortOfOpt());

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function releasePledges(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
        onlyRightholder(sn, caller)
    {
        (, , , , , , uint8 state) = _boo.getOption(sn.shortOfOpt());

        require(state == 6, "option NOT revoked");

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
    }
}
