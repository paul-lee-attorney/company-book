/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/SNParser.sol";

import "./IBOOKeeper.sol";

contract BOOKeeper is IBOOKeeper, BOOSetting, BOSSetting {
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(bytes32 sn, uint40 caller) {
        (, uint40 rightholder, , , , , ) = _boo.getOption(sn.ssn());
        require(caller == rightholder, "NOT rightholder");
        _;
    }

    modifier onlySeller(bytes32 sn, uint40 caller) {
        if (sn.typeOfOpt() > 0) {
            (, uint40 rightholder, , , , , ) = _boo.getOption(sn.ssn());
            require(caller == rightholder, "msgSender NOT rightholder");
        } else
            require(_boo.isObligor(sn.ssn(), caller), "msgSender NOT seller");
        _;
    }

    modifier onlyBuyer(bytes32 sn, uint40 caller) {
        if (sn.typeOfOpt() > 0)
            require(_boo.isObligor(sn.ssn(), caller), "caller NOT obligor");
        else {
            (, uint40 rightholder, , , , , ) = _boo.getOption(sn.ssn());
            require(caller == rightholder, "caller NOT rightholder");
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

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
    ) external onlyManager(1) {
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
        onlyManager(1)
    {
        _boo.addObligorIntoOpt(sn.ssn(), caller);
    }

    function releaseObligorFromOption(
        bytes32 sn,
        uint40 obligor,
        uint40 caller
    ) external onlyManager(1) onlyRightholder(sn, caller) {
        _boo.removeObligorFromOpt(sn.ssn(), obligor);
    }

    function execOption(bytes32 sn, uint40 caller)
        external
        onlyManager(1)
        onlyRightholder(sn, caller)
    {
        _boo.execOption(sn.ssn());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external onlyManager(1) onlyRightholder(sn, caller) {
        _bos.decreaseCleanPar(shareNumber.ssn(), paidPar);
        _boo.addFuture(sn.ssn(), shareNumber, paidPar, paidPar);
    }

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint40 caller
    ) external onlyManager(1) onlyRightholder(sn, caller) {
        _boo.removeFuture(sn.ssn(), ft);
        _bos.increaseCleanPar(ft.shortShareNumberOfFt(), ft.paidParOfFt());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external onlyManager(1) onlySeller(sn, caller) {
        _bos.decreaseCleanPar(shareNumber.ssn(), paidPar);
        _boo.requestPledge(sn.ssn(), shareNumber, paidPar);
    }

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint40 caller
    ) external onlyManager(1) onlySeller(sn, caller) {
        _boo.lockOption(sn.ssn(), hashLock);
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
    ) external onlyManager(1) onlyBuyer(sn, caller) {
        uint32 price = sn.rateOfOpt();

        _boo.closeOption(sn.ssn(), hashKey);

        bytes32[] memory fts = _boo.futures(sn.ssn());

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

        _recoverCleanPar(_boo.pledges(sn.ssn()));
    }

    function revokeOption(bytes32 sn, uint40 caller)
        external
        onlyManager(1)
        onlyRightholder(sn, caller)
    {
        _boo.revokeOption(sn.ssn());

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.futures(sn.ssn()));
        else _recoverCleanPar(_boo.pledges(sn.ssn()));
    }

    function releasePledges(bytes32 sn, uint40 caller)
        external
        onlyManager(1)
        onlyRightholder(sn, caller)
    {
        (, , , , , , uint8 state) = _boo.getOption(sn.ssn());

        require(state == 6, "option NOT revoked");

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.pledges(sn.ssn()));
        else _recoverCleanPar(_boo.futures(sn.ssn()));
    }
}
