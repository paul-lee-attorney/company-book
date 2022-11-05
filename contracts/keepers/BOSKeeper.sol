// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/BOSSetting.sol";
import "../common/lib/SNParser.sol";

import "./IBOSKeeper.sol";

contract BOSKeeper is IBOSKeeper, BOSSetting {
    using SNParser for bytes32;

    // ###################
    // ##   Write I/O   ##
    // ###################

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external onlyManager(1) {
        _bos.setPayInAmount(ssn, amount, hashLock);
    }

    function requestPaidInCapital(
        uint32 ssn,
        string memory hashKey,
        uint40 caller
    ) external onlyManager(1) {
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
    ) external onlyManager(1) {
        _bos.decreaseCapital(ssn, paid, par);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyManager(1) {
        _bos.setMaxQtyOfMembers(max);
    }
}
