/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All rights reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "../../common/ruting/BOSSetting.sol";

import "./IBookOfPledges.sol";

contract BookOfPledges is IBookOfPledges, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.SNList;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    //Pledge 质权
    struct Pledge {
        bytes32 sn; //质押编号
        uint64 pledgedPar; // 出质票面额（数量）
        uint40 creditor; //质权人、债权人
        uint64 guaranteedAmt; //担保金额
    }

    // struct snInfo {
    //     uint8 typeOfPledge; 1   1-forSelf; 2-forOthers
    //     uint16 sequence; 2
    //     uint32 createDate; 4
    //     uint32 ssnOfShare; 4
    //     uint40 pledgor; 5
    //     uint40 debtor; 5
    // }

    // seq => Pledge
    mapping(uint32 => Pledge) private _pledges;

    // ssnOfShare => pledges SN
    mapping(uint32 => EnumerableSet.Bytes32Set) private _pledgesAttachedOn;

    uint32 private _counterOfPlds;

    ObjsRepo.SNList private _snList;

    //##################
    //##   Modifier   ##
    //##################

    modifier pledgeExist(uint32 ssn) {
        require(_snList.contains(ssn), "pledge NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 typeOfPledge,
        uint32 sequence,
        uint32 createDate,
        uint32 ssnOfShare,
        uint40 pledgor,
        uint40 debtor
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfPledge);
        _sn = _sn.dateToSN(1, sequence);
        _sn = _sn.dateToSN(5, createDate);
        _sn = _sn.dateToSN(9, ssnOfShare);
        _sn = _sn.acctToSN(13, pledgor);
        _sn = _sn.acctToSN(18, debtor);

        return _sn.bytesToBytes32();
    }

    function createPledge(
        bytes32 shareNumber,
        uint40 creditor,
        uint40 debtor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyManager(1) shareExist(shareNumber.ssn()) {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        _counterOfPlds++;

        bytes32 sn = _createSN(
            1,
            _counterOfPlds,
            uint32(block.number),
            shareNumber.ssn(),
            shareNumber.shareholder(),
            debtor
        );

        Pledge storage pld = _pledges[_counterOfPlds];

        pld.sn = sn;
        pld.pledgedPar = pledgedPar;
        pld.creditor = creditor;
        pld.guaranteedAmt = guaranteedAmt;

        _snList.add(sn);

        _pledgesAttachedOn[shareNumber.ssn()].add(sn);

        emit CreatePledge(sn, shareNumber, pledgedPar, creditor, guaranteedAmt);
    }

    function delPledge(uint32 seq) external onlyKeeper pledgeExist(seq) {
        Pledge storage pld = _pledges[seq];

        uint32 ssn = pld.sn.shortShareNumberOfPledge();

        _pledgesAttachedOn[ssn].remove(pld.sn);

        if (_pledgesAttachedOn[ssn].length() == 0)
            delete _pledgesAttachedOn[ssn];

        _snList.remove(pld.sn);

        delete _pledges[seq];

        emit DelPledge(pld.sn);
    }

    function updatePledge(
        uint32 seq,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyKeeper pledgeExist(seq) {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        Pledge storage pld = _pledges[seq];

        pld.creditor = creditor;
        pld.pledgedPar = pledgedPar;
        pld.guaranteedAmt = guaranteedAmt;

        emit UpdatePledge(pld.sn, pledgedPar, guaranteedAmt);
    }

    //##################
    //##    读接口    ##
    //##################

    function pledgesOf(bytes32 sn) external view returns (bytes32[]) {
        return _pledgesAttachedOn[sn.ssn()].values();
    }

    function counterOfPledges() external view returns (uint32) {
        return _counterOfPlds;
    }

    function isPledge(uint32 seq) external view returns (bool) {
        return _snList.contains(seq);
    }

    function snList() external view returns (bytes32[]) {
        return _snList.values();
    }

    function getPledge(uint32 seq)
        external
        view
        pledgeExist(seq)
        returns (
            bytes32 sn,
            uint64 pledgedPar,
            uint40 creditor,
            uint64 guaranteedAmt
        )
    {
        Pledge storage pld = _pledges[seq];

        sn = pld.sn;
        pledgedPar = pld.pledgedPar;
        creditor = pld.creditor;
        guaranteedAmt = pld.guaranteedAmt;
    }
}
