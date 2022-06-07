/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOPSetting.sol";

import "../common/lib/SNParser.sol";

contract BOPKeeper is BOSSetting, BOPSetting {
    using SNParser for bytes32;

    // ################
    // ##   Pledge   ##
    // ################

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        uint32 creditor,
        uint32 debtor,
        uint256 guaranteedAmt,
        uint32 caller
    ) external onlyDirectKeeper currentDate(createDate) {
        require(shareNumber.shareholder() == caller, "NOT shareholder");

        _bos.decreaseCleanPar(shareNumber.short(), pledgedPar);

        _bop.createPledge(
            shareNumber,
            createDate,
            creditor,
            debtor,
            pledgedPar,
            guaranteedAmt
        );
    }

    function updatePledge(
        bytes32 sn,
        uint32 creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt,
        uint32 caller
    ) external onlyDirectKeeper {
        require(pledgedPar > 0, "ZERO pledgedPar");

        bytes6 shortShareNumber = sn.shortShareNumberOfPledge();

        (, uint256 orgPledgedPar, uint32 orgCreditor, ) = _bop.getPledge(
            sn.shortOfPledge()
        );

        if (pledgedPar < orgPledgedPar) {
            require(caller == orgCreditor, "NOT creditor");
            _bos.increaseCleanPar(shortShareNumber, orgPledgedPar - pledgedPar);
        } else if (pledgedPar > orgPledgedPar) {
            require(caller == sn.pledgorOfPledge(), "NOT pledgor");
            _bos.decreaseCleanPar(shortShareNumber, pledgedPar - orgPledgedPar);
        }

        _bop.updatePledge(
            sn.shortOfPledge(),
            creditor,
            pledgedPar,
            guaranteedAmt
        );
    }

    function delPledge(bytes32 sn, uint32 caller) external onlyDirectKeeper {
        (, uint256 pledgedPar, uint32 creditor, ) = _bop.getPledge(
            sn.shortOfPledge()
        );

        require(caller == creditor, "NOT creditor");

        _bos.increaseCleanPar(sn.shortShareNumberOfPledge(), pledgedPar);

        _bop.delPledge(sn.shortOfPledge());
    }
}
