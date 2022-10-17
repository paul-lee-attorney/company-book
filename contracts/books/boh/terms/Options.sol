// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/ruting/BOSSetting.sol";

import "../../../common/lib/EnumerableSet.sol";

import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";

import "./IOptions.sol";

contract Options is IOptions, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Option {
        bytes32 sn;
        uint64 paid;
        uint64 par;
        uint40 rightholder;
        EnumerableSet.UintSet obligors;
    }

    // bytes32 snInfo{
    //      uint8 typeOfOpt; 0  //0-call(price); 1-put(price); 2-call(roe); 3-pub(roe); 4-call(price) & cnds; 5-put(price) & cnds; 6-call(roe) & cnds; 7-put(roe) & cnds;
    //      uint40 ssnOfOpts; 1, 5
    //      uint32 triggerDate; 6, 4
    //      uint8 exerciseDays; 10, 1
    //      uint8 closingDays; 11, 1
    //      uint32 rate; 12, 4 // Price, ROE, IRR or other key rate to deduce price.
    //      uint8 logicOperator; 16, 1 // 0-not applicable; 1-and; 2-or; ...
    //      uint8 compareOperator_1; 17, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_1; 18, 4
    //      uint8 compareOperator_2; 22, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_2; 23, 4
    // }

/*
    _options[0] {
        sn;
        paid: ;
        par: qtyOfOpts;
        rightholder: counterOfOpts;
        obligors: snList;
    }
*/

    // ssn => Option
    mapping(uint256 => Option) private _options;

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(uint40 ssn) {
        require(isOpt(ssn), "option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createSN(
        uint8 typeOfOpt, //0-call(price); 1-put(price); 2-call(ROE); 3-put(ROE)
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate
    ) private returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _increaseCounterOfOpts();

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.acctToSN(1, counterOfOpts());
        _sn = _sn.dateToSN(6, triggerDate);
        _sn[10] = bytes1(exerciseDays);
        _sn[11] = bytes1(closingDays);
        _sn = _sn.dateToSN(12, rate);

        sn = _sn.bytesToBytes32();
    }

    function _increaseCounterOfOpts() private {
        _options[0].rightholder++;
    }

    function createOption(
        uint8 typeOfOpt,
        uint40 _rightholder,
        uint40 obligor,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate,
        uint64 paid,
        uint64 par
    ) external onlyAttorney {
        require(typeOfOpt < 8, "typeOfOpt overflow");
        require(triggerDate >= block.timestamp - 15 minutes, "triggerDate NOT future");
        require(rate > 0, "rate is ZERO");
        require(paid > 0, "ZERO paid");
        require(par >= paid, "INSUFFICIENT par");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        bytes32 _sn = _createSN(
            typeOfOpt,
            triggerDate,
            exerciseDays,
            closingDays,
            rate
        );
        
        uint40 ssn = counterOfOpts();

        Option storage opt = _options[ssn];

        opt.sn = _sn;
        opt.par = par;
        opt.paid = paid;

        opt.rightholder = _rightholder;
        opt.obligors.add(obligor);

        _options[0].obligors.add(uint256(_sn));

        emit CreateOpt(ssn, paid, par, _rightholder, obligor);
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

        _sn = _sn.bytes32ToSN(0, orgSN, 0, 16);
        _sn[16] = bytes1(logicOperator);
        _sn[17] = bytes1(compareOperator_1);
        _sn = _sn.dateToSN(18, para_1);
        _sn[22] = bytes1(compareOperator_2);
        _sn = _sn.dateToSN(23, para_2);

        sn = _sn.bytesToBytes32();
    }

    function addConditions(
        uint40 ssn,
        uint8 logicOperator,
        uint8 compareOperator_1,
        uint32 para_1,
        uint8 compareOperator_2,
        uint32 para_2
    ) external onlyAttorney {
        Option storage opt = _options[ssn];

        require(opt.sn.typeOfOpt() > 3, "WRONG typeOfOption");

        bytes32 _sn = _addConditions(
            opt.sn,
            logicOperator,
            compareOperator_1,
            para_1,
            compareOperator_2,
            para_2
        );

        if (_options[0].obligors.remove(uint256(opt.sn)) ) {
            opt.sn = _sn;
            _options[0].obligors.add(uint256(_sn));
            emit AddConditions(ssn, _sn);
        }
    }

    function addObligorIntoOpt(uint40 ssn, uint40 obligor)
        external
        onlyAttorney
        optionExist(ssn)
    {
        if (_options[ssn].obligors.add(obligor)) 
            emit AddObligorIntoOpt(ssn, obligor);
    }

    function removeObligorFromOpt(uint40 ssn, uint40 obligor)
        external
        onlyAttorney
        optionExist(ssn)
    {
        if (_options[ssn].obligors.remove(obligor))
            emit RemoveObligorFromOpt(ssn, obligor);
    }

    function delOption(uint40 ssn) external onlyAttorney optionExist(ssn) {
        Option storage opt = _options[ssn];

        if (_options[0].obligors.remove(uint256(opt.sn))) {
            delete _options[ssn];
            emit DelOpt(ssn);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOpts() public view returns (uint40) {
        return _options[0].rightholder;
    }

    function isOpt(uint40 ssn) public view returns (bool) {
        return ssn > 0 && _options[ssn].sn.ssnOfOpt()==ssn;
    }

    function qtyOfOpts() external view returns(uint40) {
        return uint40(_options[0].obligors.length());
    }

    function isObligor(uint40 ssn, uint40 acct)
        external
        view
        optionExist(ssn)
        returns (bool)
    {
        return _options[ssn].obligors.contains(acct);
    }

    function getOpt(uint40 ssn)
        external
        view
        optionExist(ssn)
        returns (
            bytes32 sn,
            uint64 paid, 
            uint64 par,
            uint40 rightholder
        )
    {
        Option storage opt = _options[ssn];

        sn = opt.sn;
        paid = opt.paid;
        par = opt.par;
        rightholder = opt.rightholder;
    }

    function obligors(uint40 ssn)
        external
        view
        optionExist(ssn)
        returns (uint40[] memory)
    {
        return _options[ssn].obligors.valuesToUint40();
    }

    function isRightholder(uint40 ssn, uint40 acct)
        external
        view
        optionExist(ssn)
        returns (bool)
    {
        return _options[ssn].rightholder == acct;
    }

    function ssnList() external view returns (uint40[] memory) {
        return _options[0].obligors.valuesToUint40();
    }
}
