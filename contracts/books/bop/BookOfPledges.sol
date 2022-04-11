/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/SafeMath.sol";
import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/SNFactory.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "../../common/config/BOSSetting.sol";

contract BookOfPledges is BOSSetting {
    using SafeMath for uint8;
    using SNFactory for bytes;
    using ShareSNParser for bytes32;
    using ArrayUtils for bytes32[];

    //Pledge 质权
    struct Pledge {
        bytes32 shareNumber; //出资证明书编号（股票编号）
        uint256 pledgedPar; // 出质票面额（数量）
        address creditor; //质权人、债权人
        uint256 guaranteedAmt; //担保金额
    }

    // // SNInfo 质押编码规则
    // struct SNInfo {
    //     bytes6 shortShareNumber;
    //     uint16 sequence;
    //     uint32 createDate;
    //     address creditor;
    // }

    // sn => Pledge
    mapping(bytes32 => Pledge) private _pledges;

    // sn => pledge exist?
    mapping(bytes32 => bool) public isPledge;

    // shareNumber => pledges sn
    mapping(bytes32 => bytes32[]) public pledgesOf;

    uint16 public counterOfPledges;

    bytes32[] public snList;

    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        bytes32 indexed sn,
        bytes32 indexed shareNumber,
        uint256 pledgedPar,
        address creditor,
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

    modifier pledgeExist(bytes32 sn) {
        require(isPledge[sn], "pledge NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint32 createDate,
        bytes32 shareNumber,
        address creditor,
        uint256 pledgedPar
    ) private view returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.shortToSN(0, shareNumber.short());
        _sn = _sn.sequenceToSN(6, counterOfPledges);
        _sn = _sn.dateToSN(8, createDate);
        _sn = _sn.addrToSN(12, creditor);

        sn = _sn.bytesToBytes32();
    }

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        address creditor,
        uint256 guaranteedAmt
    ) external onlyBookeeper shareExist(shareNumber) {
        require(
            createDate >= now - 2 hours && createDate <= now + 2 hours,
            "NOT a current date"
        );

        require(pledgedPar > 0, "ZERO pledged parvalue");

        counterOfPledges++;

        bytes32 sn = _createSN(createDate, shareNumber, creditor, pledgedPar);

        Pledge storage pld = _pledges[sn];

        pld.shareNumber = shareNumber;
        pld.pledgedPar = pledgedPar;
        pld.creditor = creditor;
        pld.guaranteedAmt = guaranteedAmt;

        isPledge[sn] = true;
        pledgesOf[shareNumber].push(sn);
        snList.push(sn);

        emit CreatePledge(sn, shareNumber, pledgedPar, creditor, guaranteedAmt);
    }

    function delPledge(bytes32 sn) external onlyBookeeper pledgeExist(sn) {
        Pledge storage pld = _pledges[sn];

        pledgesOf[pld.shareNumber].removeByValue(sn);

        if (pledgesOf[pld.shareNumber].length == 0)
            delete pledgesOf[pld.shareNumber];

        delete isPledge[sn];
        delete _pledges[sn];

        snList.removeByValue(sn);

        emit DelPledge(sn);
    }

    function updatePledge(
        bytes32 sn,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external onlyBookeeper pledgeExist(sn) {
        require(pledgedPar > 0, "ZERO pledged parvalue");

        Pledge storage pld = _pledges[sn];

        pld.pledgedPar = pledgedPar;
        pld.guaranteedAmt = guaranteedAmt;

        emit UpdatePledge(sn, pledgedPar, guaranteedAmt);
    }

    //##################
    //##    读接口    ##
    //##################

    function parseSN(bytes32 sn)
        public
        pure
        returns (
            bytes6 short,
            uint16 sequence,
            uint32 createDate,
            address creditor
        )
    {
        short = bytes6(sn);
        sequence = uint16(bytes2(sn << 48));
        createDate = uint32(bytes4(sn << 64));
        creditor = address(uint160(sn));
    }

    function getPledge(bytes32 sn)
        external
        view
        pledgeExist(sn)
        returns (
            bytes32 shareNumber,
            uint256 pledgedPar,
            address creditor,
            uint256 guaranteedAmt
        )
    {
        Pledge storage pld = _pledges[sn];

        shareNumber = pld.shareNumber;
        pledgedPar = pld.pledgedPar;
        creditor = pld.creditor;
        guaranteedAmt = pld.guaranteedAmt;
    }
}
