// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";

import "../../../common/ruting/BOMSetting.sol";
import "../../../common/ruting/ROMSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/SNParser.sol";

import "../../../common/components/ISigPage.sol";

import "./IFirstRefusal.sol";
import "./ITerm.sol";

contract FirstRefusal is IFirstRefusal, BOMSetting, ROMSetting {
    using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    struct FR {
        bytes32 rule;
        EnumerableSet.UintSet rightholders;
    }

    // struct ruleInfo {
    //     uint8 typeOfDeal; 1-CI; 2-ST(ext); 3-ST(int);
    //     bool membersEqual;
    //     bool proRata;
    //     bool basedOnPar;
    // }

    // typeOfDeal => FR : right of first refusal
    mapping(uint256 => FR) private _firstRefusals;

    // ################
    // ##  Modifier  ##
    // ################

    // modifier beRestricted(uint8 typeOfDeal) {
    //     require(isSubject(typeOfDeal), "deal NOT restricted");
    //     _;
    // }

    // ################
    // ##   写接口   ##
    // ################

    // function _createRule(
    //     uint8 typeOfDeal,
    //     bool membersEqualOfFR,
    //     bool proRata,
    //     bool basedOnPar
    // ) private pure returns (bytes32 sn) {
    //     bytes memory _sn = new bytes(32);

    //     _sn[0] = bytes1(typeOfDeal);
    //     _sn = _sn.boolToSN(1, membersEqualOfFR);
    //     _sn = _sn.boolToSN(2, proRata);
    //     _sn = _sn.boolToSN(3, basedOnPar);

    //     return _sn.bytesToBytes32();
    // }

    function setFirstRefusal(bytes32 rule)
        external
        onlyAttorney
    {
        _firstRefusals[rule.typeOfFR()].rule = rule;

        emit SetFirstRefusal(rule);
    }

    function delFirstRefusal(uint8 typeOfFR) external onlyAttorney {
        delete _firstRefusals[typeOfFR];

        emit DelFirstRefusal(typeOfFR);
    }

    function addRightholder(uint8 typeOfDeal, uint40 rightholder)
        external
        onlyAttorney
    {
        // FR storage fr = _firstRefusals[typeOfDeal];

        // bytes32 rule = fr.rule;

        // require(!rule.membersEqualOfFR(), "Members' right are equal");

        if (_firstRefusals[typeOfDeal].rightholders.add(rightholder))
            emit AddRightholder(typeOfDeal, rightholder);
    }

    function removeRightholder(uint8 typeOfDeal, uint40 acct)
        external
        onlyAttorney
    {
        if (_firstRefusals[typeOfDeal].rightholders.remove(acct))
            emit RemoveRightholder(typeOfDeal, acct);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isSubject(uint8 typeOfDeal) public view returns (bool) {
        return _firstRefusals[typeOfDeal].rule != bytes32(0);
    }

    function ruleOfFR(uint8 typeOfDeal) external view returns (bytes32) {
        return _firstRefusals[typeOfDeal].rule;
    }

    function isRightholder(uint8 typeOfDeal, uint40 acct)
        external
        view
        returns (bool)
    {
        FR storage fr = _firstRefusals[typeOfDeal];

        if (fr.rule.membersEqualOfFR()) return _rom.isMember(acct);
        else return fr.rightholders.contains(acct);
    }

    function rightholders(uint8 typeOfDeal)
        external
        view
        returns (uint40[] memory)
    {
        FR storage fr = _firstRefusals[typeOfDeal];

        if (fr.rule.membersEqualOfFR()) return _rom.membersList();
        else return fr.rightholders.valuesToUint40();
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool) {
        require(
            IInvestmentAgreement(ia).isDeal(sn.sequence()),
            "deal not exist"
        );

        return isSubject(sn.typeOfDeal());
    }

    function isExempted(address ia, bytes32 sn) external view returns (bool) {
        if (!isTriggered(ia, sn)) return true;
        bytes32 rule = _firstRefusals[sn.typeOfDeal()].rule;

        (uint40[] memory consentParties, ) = _bom.getYea(uint256(uint160(ia)));

        uint40[] memory signers = ISigPage(ia).partiesOfDoc();

        uint40[] memory agreedParties = consentParties.combine(signers);

        if (rule.membersEqualOfFR())
            return _rom.membersList().fullyCoveredBy(agreedParties);
        else
            return
                _firstRefusals[sn.typeOfDeal()]
                    .rightholders
                    .valuesToUint40()
                    .fullyCoveredBy(agreedParties);
    }
}
