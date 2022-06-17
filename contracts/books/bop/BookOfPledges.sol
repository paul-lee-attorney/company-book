/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All rights reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/ObjGroup.sol";

import "../../common/ruting/BOSSetting.sol";

contract BookOfPledges is BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.SNList;
    using ArrayUtils for bytes32[];

    //Pledge 质权
    struct Pledge {
        bytes32 sn; //质押编号
        uint256 pledgedPar; // 出质票面额（数量）
        uint40 creditor; //质权人、债权人
        uint256 guaranteedAmt; //担保金额
    }

    // struct snInfo {
    //     uint8 typeOfPledge; 1   1-forSelf; 2-forOthers
    //     uint16 sequence; 2
    //     uint32 createDate; 4
    //     bytes6 shortOfShare; 6
    //     uint40 pledgor; 5
    //     uint40 debtor; 5
    // }

    // ssn => Pledge
    mapping(bytes6 => Pledge) private _pledges;

    // shortShareNumber => pledges SN
    mapping(bytes6 => bytes32[]) public pledgesOf;

    uint16 public counterOfPledges;

    ObjGroup.SNList private _snList;

    constructor(uint40 bookeeper, address regCenter) public {
        init(_msgSender(), bookeeper, regCenter);
    }

    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        bytes32 indexed sn,
        bytes32 indexed shareNumber,
        uint256 pledgedPar,
        uint40 creditor,
        uint256 guaranteedAmt
    );

    event DelPledge(bytes32 indexed sn);

    event UpdatePledge(
        bytes32 indexed sn,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    );

    //##################
    //##   Modifier   ##
    //##################

    modifier pledgeExist(bytes6 ssn) {
        require(_snList.isItem[ssn], "pledge NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 typeOfPledge,
        uint16 sequence,
        uint32 createDate,
        bytes6 shortOfShare,
        uint40 pledgor,
        uint40 debtor
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfPledge);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, createDate);
        _sn = _sn.shortToSN(7, shortOfShare);
        _sn = _sn.acctToSN(13, pledgor);
        _sn = _sn.acctToSN(18, debtor);

        return _sn.bytesToBytes32();
    }

    function createPledge(
        bytes32 shareNumber,
        uint32 createDate,
        uint40 creditor,
        uint40 debtor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external onlyDirectKeeper shareExist(shareNumber.short()) {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        counterOfPledges++;

        bytes32 sn = _createSN(
            1,
            counterOfPledges,
            createDate,
            shareNumber.short(),
            shareNumber.shareholder(),
            debtor
        );

        bytes6 ssn = sn.short();

        Pledge storage pld = _pledges[ssn];

        pld.sn = sn;
        pld.pledgedPar = pledgedPar;
        pld.creditor = creditor;
        pld.guaranteedAmt = guaranteedAmt;

        // isPledge[ssn] = true;
        // sn.insertToQue(snList);

        _snList.addItem(sn);

        sn.insertToQue(pledgesOf[shareNumber.short()]);

        emit CreatePledge(sn, shareNumber, pledgedPar, creditor, guaranteedAmt);
    }

    function delPledge(bytes6 ssn) external onlyKeeper pledgeExist(ssn) {
        Pledge storage pld = _pledges[ssn];

        pledgesOf[pld.sn.shortShareNumberOfPledge()].removeByValue(pld.sn);

        if (pledgesOf[pld.sn.shortShareNumberOfPledge()].length == 0)
            delete pledgesOf[pld.sn.shortShareNumberOfPledge()];

        // snList.removeByValue(pld.sn);

        // delete isPledge[ssn];

        _snList.removeItem(pld.sn);

        delete _pledges[ssn];

        emit DelPledge(pld.sn);
    }

    function updatePledge(
        bytes6 ssn,
        uint40 creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external onlyKeeper pledgeExist(ssn) {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        Pledge storage pld = _pledges[ssn];

        pld.creditor = creditor;
        pld.pledgedPar = pledgedPar;
        pld.guaranteedAmt = guaranteedAmt;

        emit UpdatePledge(pld.sn, pledgedPar, guaranteedAmt);
    }

    //##################
    //##    读接口    ##
    //##################

    function isPledge(bytes6 ssn) external view onlyUser returns (bool) {
        return _snList.isItem[ssn];
    }

    function snList() external view onlyUser returns (bytes32[]) {
        return _snList.items;
    }

    function getPledge(bytes6 ssn)
        external
        view
        pledgeExist(ssn)
        onlyUser
        returns (
            bytes32 sn,
            uint256 pledgedPar,
            uint40 creditor,
            uint256 guaranteedAmt
        )
    {
        Pledge storage pld = _pledges[ssn];

        sn = pld.sn;
        pledgedPar = pld.pledgedPar;
        creditor = pld.creditor;
        guaranteedAmt = pld.guaranteedAmt;
    }
}
