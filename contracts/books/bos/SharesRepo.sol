/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/SafeMath.sol";
import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/SNFactory.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "../../common/config/AdminSetting.sol";

contract SharesRepo is AdminSetting {
    using SNFactory for bytes;
    using ShareSNParser for bytes32;
    using SafeMath for uint256;
    using ArrayUtils for uint256[];
    using ArrayUtils for address[];
    using ArrayUtils for bytes32[];

    //Share 股票
    struct Share {
        bytes32 shareNumber; //出资证明书编号（股票编号）
        uint256 parValue; //票面金额（注册资本面值）
        uint256 paidPar; //实缴出资
        uint256 cleanPar; //清洁金额（扣除出质、远期票面金额）
        uint32 paidInDeadline; //出资期限（时间戳）
        uint256 unitPrice; //发行价格（最小单位为分）
        uint8 state; //股票状态 （0：正常，1：出质，2：远期占用; 3:1+2; 4:查封; 5:1+4; 6:2+4; 7:1+2+4 ）
    }

    // SNInfo: 股票编号编码规则
    // struct SNInfo {
    //     uint8 class; //股份类别（投资轮次）
    //     uint16 sequence; //顺序编码
    //     uint32 issueDate; //发行日期
    //     address shareholder; //股东地址
    //     bytes5 preSN; //来源股票编号索引（sequence + issueDate(前24位, 精度误差256秒))
    // }

    //注册资本总额
    uint256 public regCap;

    //实缴出资总额
    uint256 public paidCap;

    //shareNumber => Share
    mapping(bytes32 => Share) internal _shares;

    //shareNumber => exist?
    mapping(bytes32 => bool) public isShare;

    //股权序列号计数器（2**16-1, 0-65535）
    uint16 public counterOfShares;

    //类别序列号计数器(2**8-1, 0-255)
    uint8 public counterOfClasses;

    //shareNumber数组
    bytes32[] internal _snList;

    //##################
    //##    Event     ##
    //##################

    event IssueShare(
        bytes32 indexed shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 paidInDeadline,
        uint256 unitPrice
    );

    event PayInCapital(
        bytes32 indexed shareNumber,
        uint256 amount,
        uint32 paidInDate
    );

    event SubAmountFromShare(
        bytes32 indexed shareNumber,
        uint256 parValue,
        uint256 paidPar
    );

    event CapIncrease(
        uint256 parValue,
        uint256 regCap,
        uint256 paidPar,
        uint256 paiInCap
    );

    event CapDecrease(
        uint256 parValue,
        uint256 regCap,
        uint256 paidPar,
        uint256 paidCap
    );

    event DeregisterShare(bytes32 indexed shareNumber);

    event UpdateShareState(bytes32 indexed shareNumber, uint8 state);

    event UpdatePaidInDeadline(
        bytes32 indexed shareNumber,
        uint32 paidInDeadline
    );

    event DecreaseCleanPar(bytes32 shareNumber, uint256 parValue);

    event IncreaseCleanPar(bytes32 shareNumber, uint256 parValue);

    event PledgeShare(bytes32 indexed shareNumber, uint256 parValue);

    //##################
    //##   Modifier   ##
    //##################

    modifier notFreezed(bytes32 shareNumber) {
        require(_shares[shareNumber].state < 4, "FREEZED share");
        _;
    }

    modifier shareExist(bytes32 shareNumber) {
        require(isShare[shareNumber], "shareNumber NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createShareNumber(
        uint8 class,
        uint16 sequenceNumber,
        uint32 issueDate,
        address shareholder,
        bytes5 preSN
    ) internal pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(class);
        _sn = _sn.intToSN(1, sequenceNumber, 2);
        _sn = _sn.intToSN(3, issueDate, 4);
        _sn = _sn.addrToSN(7, shareholder);
        _sn = _sn.bytes32ToSN(27, bytes32(preSN), 0, 5); // sequenceNumber 2 + issueDate 3

        sn = _sn.bytesToBytes32();
    }

    function _issueShare(
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 paidInDeadline,
        uint256 unitPrice
    ) internal {
        // require(!isShare[shareNumber], "shareNumber is USED");

        Share storage share = _shares[shareNumber];

        share.shareNumber = shareNumber;
        share.parValue = parValue;
        share.paidPar = paidPar;
        share.cleanPar = paidPar;
        share.paidInDeadline = paidInDeadline;
        share.unitPrice = unitPrice;

        isShare[shareNumber] = true;
        shareNumber.insertToQue(_snList);

        emit IssueShare(
            shareNumber,
            parValue,
            paidPar,
            paidInDeadline,
            unitPrice
        );
    }

    function _deregisterShare(bytes32 shareNumber) internal {
        delete _shares[shareNumber];
        _snList.removeByValue(shareNumber);
        isShare[shareNumber] = false;

        emit DeregisterShare(shareNumber);
    }

    function _payInCapital(
        bytes32 shareNumber,
        uint256 amount,
        uint32 paidInDate
    ) internal {
        require(paidInDate > 0, "paidInDate NOT a PAST time");
        require(paidInDate <= now + 2 hours, "paidInDate NOT a PAST time");

        Share storage share = _shares[shareNumber];

        require(paidInDate <= share.paidInDeadline);
        require(share.paidPar + amount <= share.parValue, "amount overflow");

        share.paidPar += amount; //溢出校验已通过
        share.cleanPar += amount;

        emit PayInCapital(shareNumber, amount, paidInDate);
    }

    function _subAmountFromShare(
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    ) internal {
        // require(paidPar <= parValue, "paidPar BIGGER than parValue");

        Share storage share = _shares[shareNumber];

        // require(paidPar <= share.paidPar, "paidPar overflow");

        share.parValue -= parValue;
        share.paidPar -= paidPar;
        share.cleanPar -= paidPar;

        emit SubAmountFromShare(shareNumber, parValue, paidPar);
    }

    function _capIncrease(uint256 parValue, uint256 paidPar) internal {
        regCap += parValue;
        paidCap += paidPar;

        emit CapIncrease(parValue, regCap, paidPar, paidCap);
    }

    function _capDecrease(uint256 parValue, uint256 paidPar) internal {
        regCap -= parValue;
        paidCap -= paidPar;

        emit CapDecrease(parValue, regCap, paidPar, paidCap);
    }

    function decreaseCleanPar(bytes32 shareNumber, uint256 parValue)
        external
        shareExist(shareNumber)
        notFreezed(shareNumber)
    {
        require(parValue > 0, "ZERO parValue");

        Share storage share = _shares[shareNumber];

        require(parValue <= share.cleanPar, "INSUFFICIENT cleanPar");

        share.cleanPar -= parValue;

        if (share.state < 2) share.state += 2;

        emit DecreaseCleanPar(shareNumber, parValue);
    }

    function increaseCleanPar(bytes32 shareNumber, uint256 parValue)
        external
        shareExist(shareNumber)
    {
        require(parValue > 0, "ZERO parValue");

        Share storage share = _shares[shareNumber];
        require(
            share.paidPar >= (share.cleanPar + parValue),
            "parValue overflow"
        );

        share.cleanPar += parValue;

        if (share.cleanPar == share.paidPar && share.state != 4)
            share.state = 0;

        emit IncreaseCleanPar(shareNumber, parValue);
    }

    /// @param shareNumber - 股票编号
    /// @param state - 股票状态 （0：正常，1：出质，2：远期占用; 3:1+2; 4:查封; 5:1+4; 6:2+4; 7:1+2+4 ）
    function updateShareState(bytes32 shareNumber, uint8 state)
        external
        onlyBookeeper
        shareExist(shareNumber)
    {
        _shares[shareNumber].state = state;

        emit UpdateShareState(shareNumber, state);
    }

    /// @param shareNumber - 股票编号
    /// @param paidInDeadline - 实缴出资期限
    function updatePaidInDeadline(bytes32 shareNumber, uint32 paidInDeadline)
        external
        onlyBookeeper
        shareExist(shareNumber)
    {
        _shares[shareNumber].paidInDeadline = paidInDeadline;

        emit UpdatePaidInDeadline(shareNumber, paidInDeadline);
    }

    //##################
    //##    读接口    ##
    //##################

    function snList() external view returns (bytes32[]) {
        return _snList;
    }

    function getShare(bytes32 shareNumber)
        public
        view
        shareExist(shareNumber)
        returns (
            uint256 parValue,
            uint256 paidPar,
            uint256 cleanPar,
            uint32 paidInDeadline,
            uint256 unitPrice,
            uint8 state
        )
    {
        Share storage share = _shares[shareNumber];

        parValue = share.parValue;
        paidPar = share.paidPar;
        cleanPar = share.cleanPar;
        paidInDeadline = share.paidInDeadline;
        unitPrice = share.unitPrice;
        state = share.state;
    }

    function parseSN(bytes32 shareNumber)
        external
        view
        shareExist(shareNumber)
        returns (
            uint8 class,
            uint16 sequence,
            uint32 issueDate,
            address shareholder,
            bytes5 preSN
        )
    {
        class = uint8(bytes1(shareNumber));
        sequence = uint16(bytes2(shareNumber << 8));
        issueDate = uint32(bytes4(shareNumber << 24));
        shareholder = address(bytes20(shareNumber << 56));
        preSN = bytes5(shareNumber << 216);
    }

    function preShareNumber(bytes32 shareNumber)
        public
        view
        shareExist(shareNumber)
        returns (bytes32 preSN)
    {
        bytes5 ssn = bytes5(uint40(shareNumber));

        if (ssn > 0) {
            uint256 len = _snList.length;

            for (uint256 i = 0; i < len; i++) {
                if (ssn == bytes5(_snList[i] << 8)) {
                    preSN = _snList[i];
                    break;
                }
            }
        }
    }
}
