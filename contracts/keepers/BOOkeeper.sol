/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/interfaces/IInvestmentAgreement.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/SHASetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOPSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/SNParser.sol";

import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/access/interfaces/IAccessControl.sol";
import "../common/components/interfaces/ISigPage.sol";

import "../common/components/EnumsRepo.sol";

import "../common/utils/Context.sol";

contract BOOKeeper is
    EnumsRepo,
    BOASetting,
    SHASetting,
    BOMSetting,
    BOPSetting,
    BOOSetting,
    BOSSetting
{
    using SNParser for bytes32;

    // ################
    // ##   Events   ##
    // ################

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(bytes32 sn, uint32 caller) {
        (, uint32 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
        require(caller == rightholder, "NOT rightholder");
        _;
    }

    modifier onlySeller(bytes32 sn, uint32 caller) {
        if (sn.typeOfOpt() > 0) {
            (, uint32 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(caller == rightholder, "msgSender NOT rightholder");
        } else
            require(
                _boo.isObligor(sn.shortOfOpt(), caller),
                "msgSender NOT seller"
            );
        _;
    }

    modifier onlyBuyer(bytes32 sn, uint32 caller) {
        if (sn.typeOfOpt() > 0)
            require(
                _boo.isObligor(sn.shortOfOpt(), caller),
                "caller NOT obligor"
            );
        else {
            (, uint32 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(caller == rightholder, "caller NOT rightholder");
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function createOption(
        uint8 typeOfOpt,
        uint32 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller
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

    function joinOptionAsObligor(bytes32 sn, uint32 caller)
        external
        onlyDirectKeeper
    {
        _boo.addObligorIntoOpt(sn.shortOfOpt(), caller);
    }

    function releaseObligorFromOption(
        bytes32 sn,
        uint32 obligor,
        uint32 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _boo.removeObligorFromOpt(sn.shortOfOpt(), obligor);
    }

    function execOption(
        bytes32 sn,
        uint32 exerciseDate,
        uint32 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _boo.execOption(sn.shortOfOpt(), exerciseDate);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar,
        uint32 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.addFuture(sn.shortOfOpt(), shareNumber, paidPar, paidPar);
    }

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint32 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _boo.removeFuture(sn.shortOfOpt(), ft);
        _bos.increaseCleanPar(ft.shortShareNumberOfFt(), ft.paidParOfFt());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar,
        uint32 caller
    ) external onlyDirectKeeper onlySeller(sn, caller) {
        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.requestPledge(sn.shortOfOpt(), shareNumber, paidPar);
    }

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint32 caller
    ) external onlyDirectKeeper onlySeller(sn, caller) {
        _boo.lockOption(sn.shortOfOpt(), hashLock);
    }

    function _recoverCleanPar(bytes32[] plds) private {
        uint256 len = plds.length;

        for (uint256 i = 0; i < len; i++)
            _bos.increaseCleanPar(
                plds[i].shortShareNumberOfFt(),
                plds[i].paidParOfFt()
            );
    }

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate,
        uint32 caller
    ) external onlyDirectKeeper onlyBuyer(sn, caller) {
        uint256 price = sn.rateOfOpt();

        _boo.closeOption(sn.shortOfOpt(), hashKey, closingDate);

        bytes32[] memory fts = _boo.futures(sn.shortOfOpt());

        _recoverCleanPar(fts);

        for (uint256 i = 0; i < fts.length; i++) {
            _bos.transferShare(
                fts[i].shortShareNumberOfFt(),
                fts[i].parValueOfFt(),
                fts[i].paidParOfFt(),
                caller,
                closingDate,
                price
            );
        }

        _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function revokeOption(
        bytes32 sn,
        uint32 revokeDate,
        uint32 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _boo.revokeOption(sn.shortOfOpt(), revokeDate);

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function releasePledges(bytes32 sn, uint32 caller)
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
