/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IBookOfOptions.sol";

import "../boh/terms/IOptions.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "../../common/ruting/BOSSetting.sol";

contract BookOfOptions is IBookOfOptions, BOSSetting {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.SNList;
    using SNFactory for bytes;
    using SNParser for bytes32;

    struct Option {
        bytes32 sn;
        uint40 rightholder;
        uint32 closingDate;
        uint8 state; // 0-pending; 1-issued; 2-executed; 3-futureReady; 4-pledgeReady; 5-closed; 6-revoked; 7-expired;
        uint64[2] parValue;
        uint64[3] paidPar; // 0-value; 1-futureValue; 2-pledgedPaid
        bytes32 hashLock;
        EnumerableSet.UintSet obligors;
    }

    // bytes32 snInfo{
    //      uint8 typeOfOpt; 0, 1  //0-call(price); 1-put(price); 2-call(roe); 3-put(roe); 4-call(price) & cnds; 5-put(price) & cnds; 6-call(roe) & cnds; 7-put(roe) & cnds;
    //      uint32 counterOfOptions; 1, 4
    //      uint32 triggerDate; 5, 4
    //      uint8 exerciseDays; 9, 1
    //      uint8 closingDays; 10, 1
    //      uint32 rate; 11, 4 // Price, ROE, IRR or other key rate to deduce price.
    //      uint8 logicOperator; 15, 1 // 0-not applicable; 1-and; 2-or; ...
    //      uint8 compareOperator_1; 16, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_1; 17, 4
    //      uint8 compareOperator_2; 21, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_2; 22, 4
    // }

    // seq => Option
    mapping(uint32 => Option) private _options;

    // bytes32 future {
    //     uint32 shortShareNumber; 0-3
    //     uint64 parValue; 4-11
    //     uint64 paidPar; 12-19
    // }

    struct OracleData {
        uint32 data_1;
        uint32 data_2;
    }

    // seq => OracleData
    mapping(uint32 => OracleData) private _oracles;

    // seq => futures
    mapping(uint32 => EnumerableSet.Bytes32Set) private _futures;

    // seq => pledges
    mapping(uint32 => EnumerableSet.Bytes32Set) private _pledges;

    ObjsRepo.SNList private _snList;

    uint32 private _counterOfOpts;

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(uint32 seq) {
        require(_snList.contains(seq), "option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createSN(
        uint8 typeOfOpt, //0-call option; 1-put option
        uint32 sequence,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.dateToSN(1, sequence);
        _sn = _sn.dateToSN(5, triggerDate);
        _sn[9] = bytes1(exerciseDays);
        _sn[10] = bytes1(closingDays);
        _sn = _sn.dateToSN(11, rate);

        sn = _sn.bytesToBytes32();
    }

    function createOption(
        uint8 typeOfOpt,
        uint40 rightholder,
        uint40 obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate,
        uint64 parValue,
        uint64 paidPar
    ) external onlyKeeper returns (bytes32 sn) {
        // require(typeOfOpt < 4, "typeOfOpt overflow");
        require(triggerDate >= now + 15 minutes, "triggerDate NOT future");
        require(rate > 0, "rate is ZERO");
        require(paidPar > 0, "ZERO paidPar");
        require(parValue >= paidPar, "INSUFFICIENT parValue");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        _counterOfOpts++;

        sn = _createSN(
            typeOfOpt,
            _counterOfOpts,
            triggerDate,
            exerciseDays,
            closingDays,
            rate
        );

        Option storage opt = _options[_counterOfOpts];

        opt.sn = sn;
        opt.parValue[0] = parValue;
        opt.paidPar[0] = paidPar;

        opt.rightholder = rightholder;
        opt.obligors.add(obligor);

        opt.state = 1;

        _snList.add(sn);

        emit CreateOpt(sn, rightholder, obligor, parValue, paidPar);
    }

    function addObligorIntoOpt(uint32 seq, uint40 obligor)
        public
        onlyKeeper
        optionExist(seq)
    {
        Option storage opt = _options[seq];

        if (opt.obligors.add(obligor)) emit AddObligorIntoOpt(opt.sn, obligor);
    }

    function removeObligorFromOpt(uint32 seq, uint40 obligor)
        external
        onlyKeeper
        optionExist(seq)
    {
        Option storage opt = _options[seq];

        if (opt.obligors.remove(obligor))
            emit RemoveObligorFromOpt(opt.sn, obligor);
    }

    function _replaceSequence(bytes32 orgSN, uint32 sequence)
        private
        pure
        returns (bytes32 sn)
    {
        bytes memory _sn = new bytes(32);

        _sn = _sn.bytes32ToSN(0, orgSN, 0, 26);
        _sn = _sn.dateToSN(1, sequence);

        sn = _sn.bytesToBytes32();
    }

    function registerOption(address opts) external onlyKeeper {
        bytes32[] memory snList = IOptions(opts).snList();
        uint256 len = snList.length;

        while (len > 0) {
            uint32 seq = snList[len - 1].ssn();
            len--;

            if (!IOptions(opts).isOption(seq)) continue;

            _counterOfOpts++;

            bytes32 sn = _replaceSequence(snList[len - 1], _counterOfOpts);

            Option storage opt = _options[_counterOfOpts];

            opt.sn = sn;

            (opt.parValue[0], opt.paidPar[0]) = IOptions(opts).values(seq);

            _snList.add(sn);

            opt.rightholder = IOptions(opts).rightholder(seq);

            uint40[] memory obligors = IOptions(opts).obligors(seq);

            uint256 j = obligors.length;
            while (j > 0) {
                opt.obligors.add(obligors[j - 1]);
                j--;
            }

            opt.state = 1;

            emit RegisterOpt(sn, opt.parValue[0], opt.paidPar[0]);
        }
    }

    function updateOracle(
        uint32 seq,
        uint32 d1,
        uint32 d2
    ) external onlyKeeper optionExist(seq) {
        OracleData storage oracle = _oracles[seq];

        oracle.data_1 = d1;
        oracle.data_2 = d2;

        emit UpdateOracle(seq, d1, d2);
    }

    function execOption(uint32 seq) external onlyKeeper optionExist(seq) {
        Option storage opt = _options[seq];

        bytes32 sn = opt.sn;
        uint32 triggerDate = sn.triggerDateOfOpt();
        uint32 exerciseDays = uint32(sn.exerciseDaysOfOpt());
        uint32 closingDays = uint32(sn.closingDaysOfOpt());

        require(opt.state == 1, "option's state is NOT correct");
        require(now - 15 minutes >= triggerDate, "NOT reached TriggerDate");

        if (exerciseDays > 0)
            require(
                now + 15 minutes <= triggerDate + exerciseDays * 86400,
                "NOT in exercise period"
            );

        if (sn.typeOfOpt() > 3)
            require(
                sn.checkConditions(_oracles[seq].data_1, _oracles[seq].data_2),
                "conditions NOT satisfied"
            );

        opt.closingDate = uint32(block.timestamp) + closingDays * 86400;
        opt.state = 2;

        emit ExecOpt(sn);
    }

    function _createFuture(
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) internal pure returns (bytes32 ft) {
        bytes memory _ft = new bytes(32);

        _ft = _ft.bytes32ToSN(0, shareNumber, 1, 4);
        _ft = _ft.intToSN(4, parValue, 8);
        _ft = _ft.intToSN(12, paidPar, 8);

        ft = _ft.bytesToBytes32();
    }

    function addFuture(
        uint32 seq,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external onlyKeeper optionExist(seq) {
        Option storage opt = _options[seq];

        require(now - 15 minutes <= opt.closingDate, "MISSED closingDate");
        require(opt.state == 2, "option NOT exec");

        bytes32 sn = opt.sn;

        uint8 typeOfOpt = sn.typeOfOpt();

        uint32 shortOfShare = shareNumber.ssn();

        require(_bos.isShare(shortOfShare), "share NOT exist");

        if (typeOfOpt == 1)
            require(
                opt.rightholder == shareNumber.shareholder(),
                "WRONG shareholder"
            );
        else
            require(
                opt.obligors.contains(shareNumber.shareholder()),
                "WRONG sharehoder"
            );

        require(
            opt.parValue[0] >= opt.parValue[1] + parValue,
            "NOT sufficient parValue"
        );
        opt.parValue[1] += parValue;

        require(
            opt.paidPar[0] >= opt.paidPar[1] + paidPar,
            "NOT sufficient paidPar"
        );
        opt.paidPar[1] += paidPar;

        bytes32 ft = _createFuture(shareNumber, parValue, paidPar);

        if (_futures[seq].add(ft)) {
            if (
                opt.parValue[0] == opt.parValue[1] &&
                opt.paidPar[0] == opt.paidPar[1]
            ) opt.state = 3;

            emit AddFuture(sn, shareNumber, parValue, paidPar);
        }
    }

    function removeFuture(uint32 seq, bytes32 ft)
        external
        onlyKeeper
        optionExist(seq)
    {
        Option storage opt = _options[seq];
        require(opt.state < 5, "WRONG state");
        require(now - 15 minutes <= opt.closingDate, "MISSED closingDate");

        if (_futures[seq].remove(ft)) {
            opt.parValue[1] -= ft.parValueOfFt();
            opt.paidPar[1] -= ft.paidParOfFt();

            if (opt.state == 3) opt.state = 2;

            emit DelFuture(_options[seq].sn);
        }
    }

    function requestPledge(
        uint32 seq,
        bytes32 shareNumber,
        uint64 paidPar
    ) external onlyKeeper optionExist(seq) {
        Option storage opt = _options[seq];

        require(opt.state < 5, "WRONG state");
        require(opt.state > 1, "WRONG state");

        bytes32 sn = opt.sn;
        uint8 typeOfOpt = sn.typeOfOpt();
        // uint40 obligor = sn.obligorOfOpt();

        // uint32 shortOfShare = shareNumber.seq();

        if (typeOfOpt == 1)
            require(
                opt.obligors.contains(shareNumber.shareholder()),
                "WRONG shareholder"
            );
        else
            require(
                opt.rightholder == shareNumber.shareholder(),
                "WRONG sharehoder"
            );

        require(
            opt.paidPar[0] >= opt.paidPar[2] + paidPar,
            "pledge paidPar OVERFLOW"
        );
        opt.paidPar[2] += paidPar;

        bytes32 pld = _createFuture(shareNumber, paidPar, paidPar);

        if (_pledges[seq].add(pld)) {
            if (opt.paidPar[0] == opt.paidPar[2]) opt.state = 4;

            emit AddPledge(sn, shareNumber, paidPar);
        }
    }

    function lockOption(uint32 seq, bytes32 hashLock)
        external
        optionExist(seq)
        onlyKeeper
    {
        Option storage opt = _options[seq];
        require(opt.state > 1, "WRONG state");
        opt.hashLock = hashLock;

        emit LockOpt(opt.sn, hashLock);
    }

    function closeOption(uint32 seq, string hashKey)
        external
        onlyKeeper
        optionExist(seq)
    {
        Option storage opt = _options[seq];

        require(opt.state > 1, "WRONG state");
        require(opt.state < 5, "WRONG state");
        require(now + 15 minutes <= opt.closingDate, "MISSED closingDate");
        require(opt.hashLock == keccak256(bytes(hashKey)), "WRONG key");

        opt.state = 5;

        emit CloseOpt(opt.sn, hashKey);
    }

    function revokeOption(uint32 seq) external onlyKeeper optionExist(seq) {
        Option storage opt = _options[seq];

        require(opt.state < 5, "WRONG state");
        require(
            now - 15 minutes > opt.closingDate,
            "closing period NOT expired"
        );

        opt.state = 6;

        emit RevokeOpt(opt.sn);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint32) {
        return _counterOfOpts;
    }

    function isOption(uint32 seq) public view returns (bool) {
        return _snList.contains(seq);
    }

    function getOption(uint32 seq)
        external
        view
        returns (
            bytes32 sn,
            uint40 rightholder,
            uint32 closingDate,
            uint64 parValue,
            uint64 paidPar,
            bytes32 hashLock,
            uint8 state
        )
    {
        Option memory opt = _options[seq];
        sn = opt.sn;
        rightholder = opt.rightholder;
        closingDate = opt.closingDate;
        parValue = opt.parValue[0];
        paidPar = opt.paidPar[0];
        hashLock = opt.hashLock;
        state = opt.state;
    }

    function isObligor(uint32 seq, uint40 acct) external view returns (bool) {
        return _options[seq].obligors.contains(acct);
    }

    function obligors(uint32 seq) external view returns (uint40[]) {
        return _options[seq].obligors.valuesToUint40();
    }

    function stateOfOption(uint32 seq) external view returns (uint8) {
        return _options[seq].state;
    }

    function futures(uint32 seq) external view returns (bytes32[]) {
        return _futures[seq].values();
    }

    function pledges(uint32 seq) external view returns (bytes32[]) {
        return _pledges[seq].values();
    }

    function snList() external view returns (bytes32[]) {
        return _snList.values();
    }

    function oracle(uint32 seq) external view returns (uint32 d1, uint32 d2) {
        OracleData storage ora = _oracles[seq];

        d1 = ora.data_1;
        d2 = ora.data_2;
    }
}
