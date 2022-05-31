/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All rights reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

import "../../common/ruting/BOSSetting.sol";

contract BookOfPledges is BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ArrayUtils for bytes32[];

    //Pledge 质权
    struct Pledge {
        bytes32 sn; //质押编号
        uint256 pledgedPar; // 出质票面额（数量）
        uint32 creditor; //质权人、债权人
        uint256 guaranteedAmt; //担保金额
    }

    // struct snInfo {
    //     bytes6 shortOfShare; 6
    //     uint16 sequence; 2
    //     uint32 createDate; 4
    //     uint32 pledgor; 4
    //     uint32 debtor; 4
    // }

    // ssn => Pledge
    mapping(bytes6 => Pledge) private _pledges;

    // ssn => pledge exist?
    mapping(bytes6 => bool) public isPledge;

    // shortShareNumber => pledges SN
    mapping(bytes6 => bytes32[]) public pledgesOf;

    uint16 public counterOfPledges;

    bytes32[] public snList;

    constructor(uint32 bookeeper, address regCenter) public {
        init(_msgSender(), bookeeper, regCenter);
    }

    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        bytes32 indexed sn,
        bytes32 indexed shareNumber,
        uint256 pledgedPar,
        uint32 creditor,
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
        require(isPledge[ssn], "pledge NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        bytes6 shortOfShare,
        uint16 sequence,
        uint32 createDate,
        uint32 pledgor,
        uint32 debtor
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.shortToSN(0, shortOfShare);
        _sn = _sn.sequenceToSN(6, sequence);
        _sn = _sn.dateToSN(8, createDate);
        _sn = _sn.dateToSN(12, pledgor);
        _sn = _sn.dateToSN(16, debtor);

        return _sn.bytesToBytes32();
    }

    function createPledge(
        bytes32 shareNumber,
        uint32 createDate,
        uint32 creditor,
        uint32 debtor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    )
        external
        onlyDirectKeeper
        shareExist(shareNumber.short())
        currentDate(createDate)
    {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        counterOfPledges++;

        bytes32 sn = _createSN(
            shareNumber.short(),
            counterOfPledges,
            createDate,
            shareNumber.shareholder(),
            debtor
        );

        bytes6 ssn = sn.shortOfPledge();

        Pledge storage pld = _pledges[ssn];

        pld.sn = sn;
        pld.pledgedPar = pledgedPar;
        pld.creditor = creditor;
        pld.guaranteedAmt = guaranteedAmt;

        isPledge[ssn] = true;
        sn.insertToQue(pledgesOf[shareNumber.short()]);
        sn.insertToQue(snList);

        emit CreatePledge(sn, shareNumber, pledgedPar, creditor, guaranteedAmt);
    }

    function delPledge(bytes6 ssn) external onlyKeeper pledgeExist(ssn) {
        Pledge storage pld = _pledges[ssn];

        pledgesOf[pld.sn.shortShareNumberOfPledge()].removeByValue(pld.sn);

        if (pledgesOf[pld.sn.shortShareNumberOfPledge()].length == 0)
            delete pledgesOf[pld.sn.shortShareNumberOfPledge()];

        snList.removeByValue(pld.sn);

        delete isPledge[ssn];
        delete _pledges[ssn];

        emit DelPledge(pld.sn);
    }

    function updatePledge(
        bytes6 ssn,
        uint32 creditor,
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

    function getPledge(bytes6 ssn)
        external
        view
        pledgeExist(ssn)
        returns (
            bytes32 sn,
            uint256 pledgedPar,
            uint32 creditor,
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
