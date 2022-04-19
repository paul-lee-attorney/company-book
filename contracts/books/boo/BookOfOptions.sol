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
    using SNFactory for bytes32;
    using ShareSNParser for bytes32;
    using OptionSNParser for bytes32;

    struct Option {
        bytes32 sn;
        address rightholder;
        uint32 closingDate;
        uint256 parValue;
        bytes32 hashLock;
        uint8 state; // 0-pending; 1-issued; 2-executed; 3-futureReady; 4-closed; 5-expired;
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
    //     uint208 parValue; 6-31
    // }

    // ssn => futures
    mapping(bytes6 => bytes32[]) public futures;

    // ssn => bool
    mapping(bytes6 => bool) public isOption;

    bytes32[] private _snList;

    uint16 public counterOfOptions;

    // ################
    // ##   Event    ##
    // ################

    event SetOpt(bytes32 indexed sn, address rightholder, uint256 parValue);

    event DelOpt(bytes32 indexed sn);

    event CloseOpt(bytes32 indexed sn, string hashKey);

    event SetOptState(bytes32 indexed sn, uint8 state);

    event ExecOpt(bytes32 indexed sn, uint32 exerciseDate, bytes32 hashLock);

    event RevokeOpt(bytes32 indexed sn);

    event AddFuture(bytes32 indexed sn, bytes32 shareNumber, uint256 parValue);

    event DelFuture(bytes32 indexed sn, bytes32 shareNumber, uint256 parValue);

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
        uint256 parValue
    ) external onlyKeeper {
        require(typeOfOpt < 2, "typeOfOpt overflow");
        require(triggerDate > now, "triggerDate NOT future");
        require(price > 0, "price is ZERO");
        require(parValue > 0, "ZERO parValue");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        counterOfOptions++;

        bytes32 sn = createSN(
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
        opt.parValue = parValue;
        opt.state = 1;

        isOption[ssn] = true;
        sn.insertToQue(_snList);

        emit SetOpt(sn, rightholder, parValue);
    }

    function addFuture(
        bytes6 ssn,
        bytes32 shareNumber,
        uint256 parValue
    ) external onlyKeeper optionExist(ssn) {
        Option storage opt = _options[ssn];

        require(opt.state == 2, "WRONG state of option");

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

        (, , , uint256 cleanPar, , , ) = _bos.getShare(shortOfShare);
        require(cleanPar >= parValue, "NOT sufficient paidInAmout");

        uint256 balance = _balanceOfOpt(opt.parValue, ssn);

        bytes32 ft;

        if (balance > parValue) ft = _createFuture(shareNumber, parValue);
        else {
            ft = _createFuture(shareNumber, balance);
            opt.state = 3;
        }

        ft.insertToQue(futures[ssn]);

        emit AddFuture(sn, shareNumber, parValue);
    }

    function _balanceOfOpt(uint256 balance, bytes6 ssn)
        private
        returns (uint256)
    {
        bytes32[] memory fts = futures[ssn];
        uint256 len = fts.length;

        for (uint256 i = 0; i < len; i++)
            balance -= uint256(bytes26(fts[i] << 48));

        return balance;
    }

    function removeFuture(
        bytes6 ssn,
        bytes32 shareNumber,
        uint256 parValue
    ) external onlyKeeper optionExist(ssn) {
        bytes32 ft = _createFuture(shareNumber, parValue);

        bytes32[] storage fts = futures[ssn];

        (bool exist, ) = fts.firstIndexOf(ft);

        if (exist) {
            fts.removeByValue(ft);

            // 修改：升级Bookeeper模块及接口，将所有簿记的写权限，归集到Bookeeper
            _bos.increaseCleanPar(shareNumber.short(), parValue);

            emit DelFuture(_options[ssn].sn, shareNumber, parValue);
        }
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
            bytes32 hashLock,
            uint8 state
        )
    {
        Option memory opt = _options[ssn];
        sn = opt.sn;
        rightholder = opt.rightholder;
        closingDate = opt.closingDate;
        parValue = opt.parValue;
        hashLock = opt.hashLock;
        state = opt.state;
    }

    function getSNList() external view returns (bytes32[] list) {
        list = _snList;
    }

    function execOption(
        bytes6 ssn,
        uint32 exerciseDate,
        bytes32 hashLock
    ) external onlyKeeper optionExist(ssn) currentDate(exerciseDate) {
        Option storage opt = _options[ssn];

        bytes32 sn = opt.sn;
        uint32 triggerDate = sn.triggerDateOfOpt();
        uint8 exerciseDays = sn.exerciseDaysOfOpt();
        uint8 closingDays = sn.closingDaysOfOpt();

        require(
            exerciseDate >= triggerDate &&
                exerciseDate <= triggerDate + exerciseDays * 86400,
            "NOT in exercise period"
        );

        opt.closingDate = exerciseDate + closingDays * 86400;
        opt.hashLock = hashLock;
        opt.state = 2;

        emit ExecOpt(sn, exerciseDate, hashLock);
    }

    function _createFuture(bytes32 shareNumber, uint256 parValue)
        internal
        pure
        returns (bytes32 ft)
    {
        bytes memory _ft = new bytes(32);

        _ft = _ft.bytes32ToSN(0, shareNumber, 1, 6);
        _ft = _ft.intToSN(6, parValue, 26);

        ft = _ft.bytesToBytes32();
    }

    function closeOption(bytes6 ssn, string hashKey)
        external
        onlyKeeper
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        require(opt.state == 3, "WRONG state");
        require(
            now <= opt.closingDate + 15 minutes &&
                now >= opt.closingDate - 15 minutes,
            "NOT closingDate"
        );
        require(opt.hashLock == keccak256(bytes(hashKey)), "WRONG key");

        opt.state = 4;

        // 加入： 交割FUTURE

        emit CloseOpt(opt.sn, hashKey);
    }

    function revokeOption(bytes6 ssn) external onlyKeeper optionExist(ssn) {
        Option storage opt = _options[ssn];

        require(opt.state < 4, "WRONG state");

        if (opt.state == 2 || opt.state == 3)
            require(now >= opt.closingDate + 15 minutes, "NOT expired yet");
        if (opt.state == 1) {
            uint32 triggerDate = opt.sn.triggerDateOfOpt();
            uint8 exerciseDays = opt.sn.exerciseDaysOfOpt();

            require(
                now >= triggerDate + exerciseDays * 86400 + 15 minutes,
                "available to exercise"
            );
        }

        opt.state = 5;

        emit RevokeOpt(opt.sn);
    }
}
