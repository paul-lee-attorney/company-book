/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/ObjGroup.sol";

import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";

contract Options is BOSSetting, DraftControl {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.UserGroup;
    using ObjGroup for ObjGroup.SNList;

    struct Option {
        bytes32 sn;
        uint40 rightholder;
        ObjGroup.UserGroup obligors;
        // mapping(address => bool) isObligor;
        // address[] obligors;
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

    // ssn => bool
    // mapping(bytes6 => bool) private _isOption;

    // bytes32[] private _snList;

    ObjGroup.SNList private _snList;

    uint16 public counterOfOptions;

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(bytes32 indexed sn, uint40 rightholder, uint40 obligor);

    event AddObligorIntoOpt(bytes32 sn, uint40 obligor);

    event RemoveObligorFromOpt(bytes32 sn, uint40 obligor);

    event DelOpt(bytes32 indexed sn);

    event AddConditions(bytes32 indexed sn);

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(bytes6 ssn) {
        require(_snList.isItem[ssn], "option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createSN(
        uint8 typeOfOpt, //0-call(price); 1-put(price); 2-call(ROE); 3-put(ROE)
        uint16 sequence,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, triggerDate);
        _sn[7] = bytes1(exerciseDays);
        _sn[8] = bytes1(closingDays);
        _sn = _sn.dateToSN(9, uint32(rate));
        _sn = _sn.dateToSN(13, uint32(parValue));
        _sn = _sn.dateToSN(17, uint32(paidPar));

        sn = _sn.bytesToBytes32();
    }

    function createOption(
        uint8 typeOfOpt,
        uint40 rightholder,
        uint40 obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) external onlyAttorney {
        require(typeOfOpt < 8, "typeOfOpt overflow");
        require(triggerDate >= now - 15 minutes, "triggerDate NOT future");
        require(rate > 0, "rate is ZERO");
        require(paidPar > 0, "ZERO paidPar");
        require(parValue >= paidPar, "INSUFFICIENT parValue");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        counterOfOptions++;

        bytes32 sn = _createSN(
            typeOfOpt,
            counterOfOptions,
            triggerDate,
            exerciseDays,
            closingDays,
            rate,
            parValue,
            paidPar
        );

        Option storage opt = _options[sn.short()];

        opt.sn = sn;
        opt.rightholder = rightholder;

        opt.obligors.addMember(obligor);

        // opt.isObligor[obligor] = true;
        // opt.obligors.push(obligor);

        _snList.addItem(sn);

        // isOption[counterOfOptions] = true;
        // _snList.push(sn);

        emit CreateOpt(sn, rightholder, obligor);
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

        _sn = _sn.bytes32ToSN(0, orgSN, 0, 21);
        _sn[21] = bytes1(logicOperator);
        _sn[22] = bytes1(compareOperator_1);
        _sn = _sn.dateToSN(23, para_1);
        _sn[27] = bytes1(compareOperator_2);
        _sn = _sn.dateToSN(28, para_2);

        sn = _sn.bytesToBytes32();
    }

    function addConditions(
        bytes6 ssn,
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

        _snList.removeItem(opt.sn);

        opt.sn = sn;

        _snList.addItem(sn);

        emit AddConditions(sn);
    }

    function addObligorIntoOpt(bytes6 ssn, uint40 obligor)
        external
        onlyAttorney
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        require(opt.obligors.addMember(obligor), "obligor ALREADY registered");
        emit AddObligorIntoOpt(opt.sn, obligor);

        // opt.isObligor[obligor] = true;
        // opt.obligors.push(obligor);
    }

    function removeObligorFromOpt(bytes6 ssn, uint40 obligor)
        external
        onlyAttorney
        optionExist(ssn)
    {
        Option storage opt = _options[ssn];

        require(opt.obligors.removeMember(obligor), "obligor NOT registered");
        emit RemoveObligorFromOpt(opt.sn, obligor);

        // delete opt.isObligor[obligor];
        // opt.obligors.removeByValue(obligor);
    }

    function delOption(bytes6 ssn) external onlyAttorney optionExist(ssn) {
        Option storage opt = _options[ssn];

        // delete isOption[ssn];
        // _snList.removeByValue(opt.sn);

        _snList.removeItem(opt.sn);

        delete _options[ssn];

        emit DelOpt(opt.sn);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function sn(bytes6 ssn)
        external
        view
        optionExist(ssn)
        onlyUser
        returns (bytes32)
    {
        return _options[ssn].sn;
    }

    function isOption(bytes6 ssn) external view onlyUser returns (bool) {
        return _snList.isItem[ssn];
    }

    function isObligor(bytes6 ssn, uint32 acct)
        external
        view
        optionExist(ssn)
        onlyUser
        returns (bool)
    {
        return _options[ssn].obligors.isMember[acct];
    }

    function getObligors(bytes6 ssn)
        external
        view
        optionExist(ssn)
        onlyUser
        returns (uint40[])
    {
        return _options[ssn].obligors.members;
    }

    function isRightholder(bytes6 ssn, uint40 acct)
        external
        view
        optionExist(ssn)
        onlyUser
        returns (bool)
    {
        return _options[ssn].rightholder == acct;
    }

    function rightholder(bytes6 ssn)
        external
        view
        optionExist(ssn)
        onlyUser
        returns (uint40)
    {
        return _options[ssn].rightholder;
    }

    function snList() external view onlyUser returns (bytes32[] list) {
        list = _snList.items;
    }
}
