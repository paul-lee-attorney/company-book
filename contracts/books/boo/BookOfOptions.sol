/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../boh/terms/interfaces/IOptions.sol";

import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/UserGroup.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

contract BookOfOptions is BOSSetting {
    using UserGroup for UserGroup.Group;
    using ArrayUtils for bytes32[];
    using ArrayUtils for uint32[];
    using SNFactory for bytes;
    using SNParser for bytes32;

    struct Option {
        bytes32 sn;
        uint32 rightholder;
        UserGroup.Group obligors;
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
    //      uint8 typeOfOpt; 0  //0-call(price); 1-put(price); 2-call(roe); 3-pub(roe); 4-call(price) & cnds; 5-put(price) & cnds; 6-call(roe) & cnds; 7-put(roe) & cnds;
    //      uint16 counterOfOptions; 1, 2
    //      uint32 triggerDate; 3, 4
    //      uint8 exerciseDays; 7, 1
    //      uint8 closingDays; 8, 1
    //      uint32 rate; 9, 4 // Price, ROE, IRR or other key rate to deduce price.
    //      uint32 parValue; 13, 4
    //      uint32 paidPar; 17, 4
    //      uint8 logicOperator; 21, 1 // 0-not applicable; 1-and; 2-or; ...
    //      uint8 compareOperator_1; 22, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_1; 23, 4
    //      uint8 compareOperator_2; 27, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_2; 28, 4
    // }

    // ssn => Option
    mapping(bytes6 => Option) private _options;

    // bytes32 future {
    //     bytes6 shortShareNumber; 0-5
    //     uint64 parValue; 6-13
    //     uint64 paidPar; 14-21
    // }

    struct OracleData {
        uint256 data_1;
        uint256 data_2;
    }

    // uint16 public counterOfData;

    OracleData private _oracles;

    // ssn => futures
    mapping(bytes6 => bytes32[]) public futures;

    // ssn => pledges
    mapping(bytes6 => bytes32[]) public pledges;

    // ssn => bool
    mapping(bytes6 => bool) public isOption;

    bytes32[] private _snList;

    uint16 public counterOfOptions;

    // constructor(address bookeeper) public {
    //     init(msg.sender, bookeeper);
    // }

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        bytes32 indexed sn,
        uint32 rightholder,
        uint32 obligor,
        uint256 parValue,
        uint256 paidPar
    );

    event RegisterOpt(bytes32 indexed sn);

    event AddObligorIntoOpt(bytes32 sn, uint32 obligor);

    event RemoveObligorFromOpt(bytes32 sn, uint32 obligor);

    // event SetState(bytes32 indexed sn, uint8 state);

    event DelOpt(bytes32 indexed sn);

    event CloseOpt(bytes32 indexed sn, string hashKey);

    event SetOptState(bytes32 indexed sn, uint8 state);

    event ExecOpt(bytes32 indexed sn, uint32 exerciseDate);

    event RevokeOpt(bytes32 indexed sn);

    event UpdateOracle(uint256 data_1, uint256 data_2);

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
        uint256 rate
    ) public pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, triggerDate);
        _sn[7] = bytes1(exerciseDays);
        _sn[8] = bytes1(closingDays);
        _sn = _sn.dateToSN(9, uint32(rate));

        sn = _sn.bytesToBytes32();
    }

    function createOption(
        uint8 typeOfOpt,
        uint32 rightholder,
        uint32 obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) external onlyKeeper returns (bytes32 sn) {
        require(typeOfOpt < 4, "typeOfOpt overflow");
        require(triggerDate >= now - 15 minutes, "triggerDate NOT future");
        require(rate > 0, "rate is ZERO");
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
            rate
        );

        bytes6 ssn = sn.shortOfOpt();

        Option storage opt = _options[ssn];

        opt.sn = sn;
        opt.rightholder = rightholder;

        opt.obligors.addMember(obligor);
        // opt.isObligor[obligor] = true;
        // opt.obligors.push(obligor);
        opt.parValue = paidPar;
        opt.parValue = parValue;
        opt.paidPar = paidPar;
        opt.state = 1;

        isOption[ssn] = true;
        _snList.push(sn);

        emit CreateOpt(sn, rightholder, obligor, parValue, paidPar);
    }

    function addObligorIntoOpt(bytes6 ssn, uint32 obligor)
        public
        onlyKeeper
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        require(opt.obligors.addMember(obligor), "obligor ALREADY registered");

        // opt.isObligor[obligor] = true;
        // opt.obligors.push(obligor);

        emit AddObligorIntoOpt(opt.sn, obligor);
    }

    function removeObligorFromOpt(bytes6 ssn, uint32 obligor)
        external
        onlyKeeper
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        require(opt.obligors.removeMember(obligor), "obligor NOT registered");

        // delete opt.isObligor[obligor];
        // opt.obligors.removeByValue(obligor);

        emit RemoveObligorFromOpt(opt.sn, obligor);
    }

    function _replaceSequence(bytes32 orgSN, uint16 sequence)
        private
        pure
        returns (bytes32 sn)
    {
        bytes memory _sn = new bytes(32);

        _sn = _sn.bytes32ToSN(0, orgSN, 0, 32);
        _sn = _sn.sequenceToSN(1, sequence);

        sn = _sn.bytesToBytes32();
    }

    function registerOption(address opts) external onlyKeeper {
        bytes32[] memory snList = IOptions(opts).snList();
        uint256 len = snList.length;

        for (uint256 i = 0; i < len; i++) {
            uint16 ssn = snList[i].sequenceOfOpt();
            if (!IOptions(opts).isOption(ssn)) continue;

            counterOfOptions++;

            bytes32 sn = _replaceSequence(snList[i], counterOfOptions);

            Option storage opt = _options[sn.shortOfOpt()];

            opt.sn = sn;
            isOption[sn.shortOfOpt()] = true;
            _snList.push(sn);

            opt.rightholder = IOptions(opts).rightholder(ssn);

            uint32[] memory obligors = IOptions(opts).getObligors(ssn);
            for (uint256 j = 0; j < obligors.length; j++)
                opt.obligors.addMember(obligors[j]);

            opt.parValue = sn.parValueOfOpt();
            opt.paidPar = sn.paidParOfOpt();
            opt.state = 1;

            emit RegisterOpt(sn);
        }
    }

    function updateOracle(uint256 d1, uint256 d2) external onlyKeeper {
        _oracles.data_1 = d1;
        _oracles.data_2 = d2;

        emit UpdateOracle(d1, d2);
    }

    function execOption(
        bytes6 ssn,
        uint32 caller,
        uint32 exerciseDate,
        uint32 sigHash
    ) external onlyKeeper optionExist(ssn) currentDate(exerciseDate) {
        Option storage opt = _options[ssn];

        bytes32 sn = opt.sn;
        uint32 triggerDate = sn.triggerDateOfOpt();
        uint8 exerciseDays = sn.exerciseDaysOfOpt();
        uint8 closingDays = sn.closingDaysOfOpt();

        require(opt.state == 1, "option's state is NOT correct");
        require(exerciseDate >= triggerDate, "NOT reached TriggerDate");

        if (exerciseDays > 0)
            require(
                exerciseDate <= triggerDate + exerciseDays * 86400,
                "NOT in exercise period"
            );

        if (sn.typeOfOpt() > 3)
            require(
                sn.checkConditions(_oracles.data_1, _oracles.data_2),
                "conditions NOT satisfied"
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
        _ft = _ft.intToSN(6, uint64(parValue), 8);
        _ft = _ft.intToSN(14, uint64(paidPar), 8);

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
        // uint32[] obligors = opt.obligors;

        bytes6 shortOfShare = shareNumber.short();

        require(_bos.isShare(shortOfShare), "share NOT exist");

        if (typeOfOpt == 1)
            require(
                opt.rightholder == shareNumber.shareholder(),
                "WRONG shareholder"
            );
        else
            require(
                opt.obligors.isMember(shareNumber.shareholder()),
                "WRONG sharehoder"
            );

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
        // uint32 obligor = sn.obligorOfOpt();

        // bytes6 shortOfShare = shareNumber.short();

        if (typeOfOpt == 1)
            require(
                opt.obligors.isMember(shareNumber.shareholder()),
                "WRONG shareholder"
            );
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
            uint32 rightholder,
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

    function isObligor(bytes6 ssn, uint32 acct) external view returns (bool) {
        return _options[ssn].obligors.isMember(acct);
    }

    function obligors(bytes6 ssn) external view returns (uint32[]) {
        return _options[ssn].obligors.members();
    }

    function stateOfOption(bytes6 ssn) external view returns (uint8) {
        return _options[ssn].state;
    }

    function snList() external view returns (bytes32[] list) {
        list = _snList;
    }

    function oracles() external view returns (uint256 d1, uint256 d2) {
        d1 = _oracles.data_1;
        d2 = _oracles.data_2;
    }
}
