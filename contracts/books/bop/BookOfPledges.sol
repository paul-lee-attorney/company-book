// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

import "../../common/access/AccessControl.sol";

import "./IBookOfPledges.sol";

contract BookOfPledges is IBookOfPledges, AccessControl {
    using SNFactory for bytes;
    using SNParser for bytes32;

    //Pledge 质权
    struct Pledge {
        bytes32 sn; //质押编号
        uint40 creditor; //质权人、债权人
        uint64 pledgedPar; // 出质票面额（数量）
        uint64 guaranteedAmt; //担保金额
    }

    // struct snInfo {
    //     uint32 ssnOfShare; 4
    //     uint16 sequence; 2
    //     uint32 createDate; 4
    //     uint40 pledgor; 5
    //     uint40 debtor; 5
    // }

    // _pledges[ssn][0].creditor : counterOfPledge

    // ssn => seq => Pledge
    mapping(uint256 => mapping(uint256 => Pledge)) private _pledges;

    //##################
    //##   Modifier   ##
    //##################

    modifier pledgeExist(bytes32 sn) {
        require(isPledge(sn), "BOP.pledgeExist: pledge NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        bytes32 sn,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDK {
        sn = _updateSNDate(sn);
        uint32 ssn = sn.ssnOfPledge();
        uint32 seq = sn.sequenceOfPledge();

        require(pledgedPar > 0, "BOP.createPledge: ZERO pledgedPar");

        require(
            _increaseCounterOfPledges(ssn) == seq,
            "BOP.createPledge: wrong sequence"
        );

        _pledges[ssn][seq] = Pledge({
            sn: sn,
            creditor: creditor,
            pledgedPar: pledgedPar,
            guaranteedAmt: guaranteedAmt
        });

        emit CreatePledge(sn, creditor, pledgedPar, guaranteedAmt);
    }

    function _updateSNDate(bytes32 sn) private view returns (bytes32) {
        bytes memory _sn = abi.encodePacked(sn);

        _sn = _sn.dateToSN(6, uint32(block.timestamp));

        return _sn.bytesToBytes32();
    }

    function _increaseCounterOfPledges(uint32 ssn) private returns (uint40) {
        _pledges[ssn][0].creditor++;
        return _pledges[ssn][0].creditor;
    }

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDK pledgeExist(sn) {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        Pledge storage pld = _pledges[sn.ssnOfPledge()][sn.sequenceOfPledge()];

        pld.creditor = creditor;
        pld.pledgedPar = pledgedPar;
        pld.guaranteedAmt = guaranteedAmt;

        emit UpdatePledge(sn, creditor, pledgedPar, guaranteedAmt);
    }

    //##################
    //##    读接口    ##
    //##################

    function pledgesOf(uint32 ssn) external view returns (bytes32[] memory) {
        uint40 seq = _pledges[ssn][0].creditor;

        require(seq > 0, "BOP.pledgesOf: no pledges found");

        bytes32[] memory output = new bytes32[](seq);

        while (seq > 0) {
            output[seq - 1] = _pledges[ssn][seq].sn;
            seq--;
        }

        return output;
    }

    function counterOfPledges(uint32 ssn) public view returns (uint32) {
        return uint32(_pledges[ssn][0].creditor);
    }

    function isPledge(bytes32 sn) public view returns (bool) {
        uint32 ssn = sn.ssnOfPledge();
        uint32 seq = sn.sequenceOfPledge();

        return ssn > 0 && _pledges[ssn][seq].sn.sequenceOfPledge() == seq;
    }

    function getPledge(bytes32 sn)
        external
        view
        pledgeExist(sn)
        returns (
            uint40 creditor,
            uint64 pledgedPar,
            uint64 guaranteedAmt
        )
    {
        Pledge storage pld = _pledges[sn.ssnOfPledge()][sn.sequenceOfPledge()];

        creditor = pld.creditor;
        pledgedPar = pld.pledgedPar;
        guaranteedAmt = pld.guaranteedAmt;
    }
}
