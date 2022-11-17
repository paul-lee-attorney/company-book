// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/BOSSetting.sol";
import "../common/lib/SNParser.sol";
import "./IBOSKeeper.sol";

contract BOAKeeper is
    IBOSKeeper,
    BOSSetting
{
    using SNParser for bytes32;

    // #############
    // ##   BOS   ##
    // #############

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external onlyDK {
        _bos.setPayInAmount(ssn, amount, hashLock);
    }

    function requestPaidInCapital(
        uint32 ssn,
        string memory hashKey,
        uint40 caller
    ) external onlyDK {
        (bytes32 shareNumber, , , , ) = _bos.getShare(ssn);
        require(
            caller == shareNumber.shareholder(),
            "caller is not shareholder"
        );
        _bos.requestPaidInCapital(ssn, hashKey);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external onlyDK {
        _bos.decreaseCapital(ssn, paid, par);
    }

    function updatePaidInDeadline(uint32 ssn, uint32 line)
        external
        onlyDK
    {
        _bos.updatePaidInDeadline(ssn, line);
    }
}
