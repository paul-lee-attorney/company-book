// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOPSetting.sol";

import "../common/lib/SNParser.sol";

import "./IBOPKeeper.sol";

contract BOPKeeper is IBOPKeeper, BOPSetting, BOSSetting {
    using SNParser for bytes32;

    // ################
    // ##   Pledge   ##
    // ################

    function createPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyManager(1) {
        require(sn.ssnOfPledge() == shareNumber.ssn(), "BOPKeeper.createPledge: wrong shareNumber");
        require(shareNumber.shareholder() == caller, "NOT shareholder");

        _bos.decreaseCleanPar(shareNumber.ssn(), pledgedPar);

        _bop.createPledge(
            sn,
            creditor,
            pledgedPar,
            guaranteedAmt
        );
    }

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyManager(1) {
        require(pledgedPar > 0, "BOPKeeper.updatePledge: ZERO pledgedPar");

        uint32 shortShareNumber = sn.ssnOfPledge();

        (uint40 orgCreditor, uint64 orgPledgedPar, ) = _bop.getPledge(sn);

        if (pledgedPar < orgPledgedPar) {
            require(caller == orgCreditor, "BOPKeeper.updatePledge: NOT creditor");
            _bos.increaseCleanPar(shortShareNumber, orgPledgedPar - pledgedPar);
        } else if (pledgedPar > orgPledgedPar) {
            require(caller == sn.pledgorOfPledge(), "BOPKeeper.updatePledge: NOT pledgor");
            _bos.decreaseCleanPar(shortShareNumber, pledgedPar - orgPledgedPar);
        }

        if (creditor != orgCreditor) {
            require(caller == orgCreditor, "BOPKeeper.updatePledge: NOT creditor");
        }

        _bop.updatePledge(sn, creditor, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn, uint40 caller) external onlyManager(1) {
        (uint40 creditor, uint64 pledgedPar, ) = _bop.getPledge(sn);

        require(caller == creditor, "NOT creditor");

        _bos.increaseCleanPar(sn.ssnOfPledge(), pledgedPar);

        _bop.updatePledge(sn, creditor, 0, 0);
    }
}
