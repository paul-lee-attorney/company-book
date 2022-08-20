/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

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
        // uint32 createDate,
        bytes32 shareNumber,
        uint64 pledgedPar,
        uint40 creditor,
        uint40 debtor,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyManager(1) {
        require(shareNumber.shareholder() == caller, "NOT shareholder");

        _bos.decreaseCleanPar(shareNumber.ssn(), pledgedPar);

        _bop.createPledge(
            shareNumber,
            // createDate,
            creditor,
            debtor,
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
        require(pledgedPar > 0, "ZERO pledgedPar");

        uint32 shortShareNumber = sn.shortShareNumberOfPledge();

        (, uint64 orgPledgedPar, uint40 orgCreditor, ) = _bop.getPledge(
            sn.ssn()
        );

        if (pledgedPar < orgPledgedPar) {
            require(caller == orgCreditor, "NOT creditor");
            _bos.increaseCleanPar(shortShareNumber, orgPledgedPar - pledgedPar);
        } else if (pledgedPar > orgPledgedPar) {
            require(caller == sn.pledgorOfPledge(), "NOT pledgor");
            _bos.decreaseCleanPar(shortShareNumber, pledgedPar - orgPledgedPar);
        }

        _bop.updatePledge(sn.ssn(), creditor, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn, uint40 caller) external onlyManager(1) {
        (, uint64 pledgedPar, uint40 creditor, ) = _bop.getPledge(sn.ssn());

        require(caller == creditor, "NOT creditor");

        _bos.increaseCleanPar(sn.shortShareNumberOfPledge(), pledgedPar);

        _bop.delPledge(sn.ssn());
    }
}
