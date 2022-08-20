/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../../common/ruting/BOSSetting.sol";

import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/ObjsRepo.sol";

import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";

import "./IOptions.sol";

contract Options is IOptions, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.SNList;

    struct Option {
        bytes32 sn;
        uint64 parValue;
        uint64 paidPar;
        uint40 rightholder;
        EnumerableSet.UintSet obligors;
    }

    // bytes32 snInfo{
    //      uint8 typeOfOpt; 0  //0-call(price); 1-put(price); 2-call(roe); 3-pub(roe); 4-call(price) & cnds; 5-put(price) & cnds; 6-call(roe) & cnds; 7-put(roe) & cnds;
    //      uint32 _counterOfOpts; 1, 4
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

    // ssn => Option
    mapping(uint32 => Option) private _options;

    ObjsRepo.SNList private _snList;

    uint32 private _counterOfOpts;

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(uint32 ssn) {
        require(_snList.contains(ssn), "option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createSN(
        uint8 typeOfOpt, //0-call(price); 1-put(price); 2-call(ROE); 3-put(ROE)
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
    ) external onlyAttorney {
        require(typeOfOpt < 8, "typeOfOpt overflow");
        require(triggerDate >= now - 15 minutes, "triggerDate NOT future");
        require(rate > 0, "rate is ZERO");
        require(paidPar > 0, "ZERO paidPar");
        require(parValue >= paidPar, "INSUFFICIENT parValue");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        _counterOfOpts++;

        bytes32 sn = _createSN(
            typeOfOpt,
            _counterOfOpts,
            triggerDate,
            exerciseDays,
            closingDays,
            rate
        );

        Option storage opt = _options[_counterOfOpts];

        opt.sn = sn;
        opt.parValue = parValue;
        opt.paidPar = paidPar;

        opt.rightholder = rightholder;
        opt.obligors.add(obligor);

        _snList.add(sn);

        emit CreateOpt(sn, parValue, paidPar, rightholder, obligor);
    }

    function _addConditions(
        bytes32 orgSN,
        uint8 logicOperator,
        uint8 compareOperator_1,
        uint32 para_1,
        uint8 compareOperator_2,
        uint32 para_2
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.bytes32ToSN(0, orgSN, 0, 15);
        _sn[15] = bytes1(logicOperator);
        _sn[16] = bytes1(compareOperator_1);
        _sn = _sn.dateToSN(17, para_1);
        _sn[21] = bytes1(compareOperator_2);
        _sn = _sn.dateToSN(22, para_2);

        sn = _sn.bytesToBytes32();
    }

    function addConditions(
        uint32 ssn,
        uint8 logicOperator,
        uint8 compareOperator_1,
        uint32 para_1,
        uint8 compareOperator_2,
        uint32 para_2
    ) external onlyAttorney {
        Option storage opt = _options[ssn];

        require(opt.sn.typeOfOpt() > 3, "WRONG typeOfOption");

        bytes32 sn = _addConditions(
            opt.sn,
            logicOperator,
            compareOperator_1,
            para_1,
            compareOperator_2,
            para_2
        );

        _snList.remove(opt.sn);

        opt.sn = sn;

        _snList.add(sn);

        emit AddConditions(sn);
    }

    function addObligorIntoOpt(uint32 ssn, uint40 obligor)
        external
        onlyAttorney
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        if (opt.obligors.add(obligor)) emit AddObligorIntoOpt(opt.sn, obligor);
    }

    function removeObligorFromOpt(uint32 ssn, uint40 obligor)
        external
        onlyAttorney
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        if (opt.obligors.remove(obligor))
            emit RemoveObligorFromOpt(opt.sn, obligor);
    }

    function delOption(uint32 ssn) external onlyAttorney optionExist(ssn) {
        Option storage opt = _options[ssn];

        _snList.remove(opt.sn);

        delete _options[ssn];

        emit DelOpt(opt.sn);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint32) {
        return _counterOfOpts;
    }

    function sn(uint32 ssn) external view optionExist(ssn) returns (bytes32) {
        return _options[ssn].sn;
    }

    function isOption(uint32 ssn) external view returns (bool) {
        return _snList.contains(ssn);
    }

    function isObligor(uint32 ssn, uint40 acct)
        external
        view
        optionExist(ssn)
        returns (bool)
    {
        return _options[ssn].obligors.contains(acct);
    }

    function values(uint32 ssn)
        external
        view
        returns (uint64 parValue, uint64 paidPar)
    {
        Option storage opt = _options[ssn];

        parValue = opt.parValue;
        paidPar = opt.paidPar;
    }

    function obligors(uint32 ssn)
        external
        view
        optionExist(ssn)
        returns (uint40[])
    {
        return _options[ssn].obligors.valuesToUint40();
    }

    function isRightholder(uint32 ssn, uint40 acct)
        external
        view
        optionExist(ssn)
        returns (bool)
    {
        return _options[ssn].rightholder == acct;
    }

    function rightholder(uint32 ssn)
        external
        view
        optionExist(ssn)
        returns (uint40)
    {
        return _options[ssn].rightholder;
    }

    function snList() external view returns (bytes32[]) {
        return _snList.values();
    }
}
