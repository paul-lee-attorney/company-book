/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/BOSSetting.sol";
import "../common/config/BOPSetting.sol";

import "../common/lib/serialNumber/ShareSNParser.sol";
import "../common/lib/serialNumber/PledgeSNParser.sol";

contract BOPKeeper is BOSSetting, BOPSetting {
    using ShareSNParser for bytes32;
    using PledgeSNParser for bytes32;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ################
    // ##   Pledge   ##
    // ################

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        address creditor,
        address debtor,
        uint256 guaranteedAmt
    ) external currentDate(createDate) {
        require(shareNumber.shareholder() == msg.sender, "NOT shareholder");

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
        address creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external {
        require(pledgedPar > 0, "ZERO pledgedPar");

        bytes6 shortShareNumber = sn.shortShareNumberOfPledge();

        (, uint256 orgPledgedPar, address orgCreditor, ) = _bop.getPledge(
            sn.shortOfPledge()
        );

        if (pledgedPar < orgPledgedPar) {
            require(msg.sender == orgCreditor, "NOT creditor");
            _bos.increaseCleanPar(shortShareNumber, orgPledgedPar - pledgedPar);
        } else if (pledgedPar > orgPledgedPar) {
            require(msg.sender == sn.pledgor(), "NOT pledgor");
            _bos.decreaseCleanPar(shortShareNumber, pledgedPar - orgPledgedPar);
        }

        _bop.updatePledge(
            sn.shortOfPledge(),
            creditor,
            pledgedPar,
            guaranteedAmt
        );
    }

    function delPledge(bytes32 sn) external {
        (, uint256 pledgedPar, address creditor, ) = _bop.getPledge(
            sn.shortOfPledge()
        );

        require(msg.sender == creditor, "NOT creditor");

        _bos.increaseCleanPar(sn.shortShareNumberOfPledge(), pledgedPar);

        _bop.delPledge(sn.shortOfPledge());
    }
}
