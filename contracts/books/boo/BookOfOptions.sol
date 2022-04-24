/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/config/BOSSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/SNFactory.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";
import "../../common/lib/serialNumber/OptionSNParser.sol";

contract BookOfOptions is BOSSetting {
    using ArrayUtils for bytes32[];
    using SNFactory for bytes;
    // using SNFactory for bytes32;
    using ShareSNParser for bytes32;
    using OptionSNParser for bytes32;

    struct Option {
        bytes32 sn;
        address rightholder;
        uint32 closingDate;
        uint256 parValue;
        uint256 paidPar;
        uint256 futurePar;
        uint256 futurePaid;
        uint256 pledgePaid;
        bytes32 hashLock;
        uint8 state; // 0-pending; 1-issued; 2-executed; 3-futureReady; 4-pledgeReady; 5-closed; 6-revoked; 7-expired;
    }

    // bytes32 snInfo{
    //      uint8 typeOfOpt; //0-call; 1-put
    //      uint16 counterOfOptions;
    //      uint32 triggerDate;
    //      uint8 exerciseDays;
    //      uint8 closingDays;
    //      address obligor;
    //      uint24 price; // IRR or other key rate to calculate price.
    // }

    // ssn => Option
    mapping(bytes6 => Option) private _options;

    // bytes32 future {
    //     uint48 shortShareNumber; 0-5
    //     uint104 parValue; 6-18
    //     uint104 paidPar; 19-31
    // }

    // ssn => futures
    mapping(bytes6 => bytes32[]) public futures;

    // ssn => pledges
    mapping(bytes6 => bytes32[]) public pledges;

    // ssn => bool
    mapping(bytes6 => bool) public isOption;

    bytes32[] private _snList;

    uint16 public counterOfOptions;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        bytes32 indexed sn,
        address rightholder,
        uint256 parValue,
        uint256 paidPar
    );

    // event SetState(bytes32 indexed sn, uint8 state);

    event DelOpt(bytes32 indexed sn);

    event CloseOpt(bytes32 indexed sn, string hashKey);

    event SetOptState(bytes32 indexed sn, uint8 state);

    event ExecOpt(bytes32 indexed sn, uint32 exerciseDate);

    event RevokeOpt(bytes32 indexed sn);

    event AddFuture(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    );

    event DelFuture(bytes32 indexed sn);

    event AddPledge(bytes32 indexed sn, bytes32 shareNumber, uint256 paidPar);

    event LockOpt(bytes32 indexed sn, bytes32 hashLock);

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(bytes6 ssn) {
        require(isOption[ssn], "option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createSN(
        uint8 typeOfOpt, //0-call option; 1-put option
        uint16 sequence,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        address obligor,
        uint256 price
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, triggerDate);
        _sn[7] = bytes1(exerciseDays);
        _sn[8] = bytes1(closingDays);
        _sn = _sn.addrToSN(9, obligor);
        _sn = _sn.intToSN(29, price, 3);

        sn = _sn.bytesToBytes32();
    }

    function createOption(
        uint8 typeOfOpt,
        address rightholder,
        address obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 price,
        uint256 parValue,
        uint256 paidPar
    ) external onlyKeeper returns (bytes32 sn) {
        require(typeOfOpt < 2, "typeOfOpt overflow");
        require(triggerDate >= now - 15 minutes, "triggerDate NOT future");
        require(price > 0, "price is ZERO");
        require(paidPar > 0, "ZERO paidPar");
        require(parValue >= paidPar, "INSUFFICIENT parValue");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        counterOfOptions++;

        sn = createSN(
            typeOfOpt,
            counterOfOptions,
            triggerDate,
            exerciseDays,
            closingDays,
            obligor,
            price
        );

        bytes6 ssn = sn.shortOfOpt();

        Option storage opt = _options[ssn];

        opt.sn = sn;
        opt.rightholder = rightholder;
        opt.parValue = paidPar;
        opt.parValue = parValue;
        opt.paidPar = paidPar;
        opt.state = 1;

        isOption[ssn] = true;
        _snList.push(sn);

        emit CreateOpt(sn, rightholder, parValue, paidPar);
    }

    // function setState(bytes6 ssn, uint8 state) external onlyKeeper {
    //     Option storage opt = _options[ssn];
    //     opt.state = state;
    //     emit SetState(opt.sn, state);
    // }

    function execOption(bytes6 ssn, uint32 exerciseDate)
        external
        onlyKeeper
        optionExist(ssn)
        currentDate(exerciseDate)
    {
        Option storage opt = _options[ssn];

        bytes32 sn = opt.sn;
        uint32 triggerDate = sn.triggerDateOfOpt();
        uint8 exerciseDays = sn.exerciseDaysOfOpt();
        uint8 closingDays = sn.closingDaysOfOpt();

        require(opt.state == 1, "option's state is NOT correct");
        require(
            exerciseDate >= triggerDate &&
                exerciseDate <= triggerDate + exerciseDays * 86400,
            "NOT in exercise period"
        );

        opt.closingDate = exerciseDate + closingDays * 86400;
        opt.state = 2;

        emit ExecOpt(sn, exerciseDate);
    }

    function _createFuture(
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    ) internal pure returns (bytes32 ft) {
        bytes memory _ft = new bytes(32);

        _ft = _ft.bytes32ToSN(0, shareNumber, 1, 6);
        _ft = _ft.intToSN(6, parValue, 13);
        _ft = _ft.intToSN(19, paidPar, 13);

        ft = _ft.bytesToBytes32();
    }

    function addFuture(
        bytes6 ssn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    ) external onlyKeeper optionExist(ssn) {
        Option storage opt = _options[ssn];

        require(now <= opt.closingDate + 15 minutes, "MISSED closingDate");
        require(opt.state == 2, "option NOT exec");

        bytes32 sn = opt.sn;

        uint8 typeOfOpt = sn.typeOfOpt();
        address obligor = sn.obligorOfOpt();

        bytes6 shortOfShare = shareNumber.short();

        require(_bos.isShare(shortOfShare), "share NOT exist");

        if (typeOfOpt == 1)
            require(
                opt.rightholder == shareNumber.shareholder(),
                "WRONG shareholder"
            );
        else require(obligor == shareNumber.shareholder(), "WRONG sharehoder");

        require(
            opt.parValue >= opt.futurePar + parValue,
            "NOT sufficient parValue"
        );
        opt.futurePar += parValue;

        require(
            opt.parValue >= opt.futurePaid + paidPar,
            "NOT sufficient paidPar"
        );
        opt.futurePaid += paidPar;

        bytes32 ft = _createFuture(shareNumber, parValue, paidPar);
        futures[ssn].push(ft);

        if (opt.parValue == opt.futurePar && opt.paidPar == opt.futurePaid)
            opt.state = 3;

        emit AddFuture(sn, shareNumber, parValue, paidPar);
    }

    function removeFuture(bytes6 ssn, bytes32 ft)
        external
        onlyKeeper
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];
        require(opt.state < 5, "WRONG state");
        require(now - 15 minutes <= opt.closingDate, "MISSED closingDate");

        bytes32[] storage fts = futures[ssn];

        (bool exist, ) = fts.firstIndexOf(ft);
        require(exist, "future NOT EXIST");

        fts.removeByValue(ft);
        opt.futurePar -= ft.parValueOfFt();
        opt.futurePaid -= ft.paidParOfFt();

        if (opt.state == 3) opt.state = 2;

        emit DelFuture(_options[ssn].sn);
    }

    function requestPledge(
        bytes6 ssn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external onlyKeeper optionExist(ssn) {
        Option storage opt = _options[ssn];

        require(opt.state < 5, "WRONG state");
        require(opt.state > 1, "WRONG state");

        bytes32 sn = opt.sn;
        uint8 typeOfOpt = sn.typeOfOpt();
        address obligor = sn.obligorOfOpt();

        // bytes6 shortOfShare = shareNumber.short();

        if (typeOfOpt == 1)
            require(obligor == shareNumber.shareholder(), "WRONG shareholder");
        else
            require(
                opt.rightholder == shareNumber.shareholder(),
                "WRONG sharehoder"
            );

        require(
            opt.paidPar >= opt.pledgePaid + paidPar,
            "pledge paidPar OVERFLOW"
        );
        opt.pledgePaid += paidPar;

        bytes32 pld = _createFuture(shareNumber, paidPar, paidPar);
        pledges[ssn].push(pld);

        if (opt.paidPar == opt.pledgePaid) opt.state = 4;

        emit AddPledge(sn, shareNumber, paidPar);
    }

    function lockOption(bytes6 ssn, bytes32 hashLock)
        external
        optionExist(ssn)
        onlyKeeper
    {
        Option storage opt = _options[ssn];
        require(opt.state > 1, "WRONG state");
        opt.hashLock = hashLock;

        emit LockOpt(opt.sn, hashLock);
    }

    function closeOption(
        bytes6 ssn,
        string hashKey,
        uint32 closingDate
    ) external onlyKeeper optionExist(ssn) currentDate(closingDate) {
        Option storage opt = _options[ssn];

        require(opt.state > 1, "WRONG state");
        require(opt.state < 5, "WRONG state");
        require(closingDate <= opt.closingDate, "MISSED closingDate");
        require(opt.hashLock == keccak256(bytes(hashKey)), "WRONG key");

        opt.state = 5;

        emit CloseOpt(opt.sn, hashKey);
    }

    function revokeOption(bytes6 ssn, uint32 revokeDate)
        external
        onlyKeeper
        optionExist(ssn)
        currentDate(revokeDate)
    {
        Option storage opt = _options[ssn];

        require(opt.state < 5, "WRONG state");
        require(revokeDate > opt.closingDate, "closing period NOT expired");

        opt.state = 6;

        emit RevokeOpt(opt.sn);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getOption(bytes6 ssn)
        external
        view
        optionExist(ssn)
        returns (
            bytes32 sn,
            address rightholder,
            uint32 closingDate,
            uint256 parValue,
            uint256 paidPar,
            bytes32 hashLock,
            uint8 state
        )
    {
        Option memory opt = _options[ssn];
        sn = opt.sn;
        rightholder = opt.rightholder;
        closingDate = opt.closingDate;
        parValue = opt.parValue;
        paidPar = opt.paidPar;
        hashLock = opt.hashLock;
        state = opt.state;
    }

    function stateOfOption(bytes6 ssn) external view returns (uint8) {
        return _options[ssn].state;
    }

    function snList() external view returns (bytes32[] list) {
        list = _snList;
    }
}
