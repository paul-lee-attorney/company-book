/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";

import "../../../common/components//ISigPage.sol";

import "./IFirstRefusal.sol";

contract FirstRefusal is IFirstRefusal, BOSSetting, BOMSetting, DraftControl {
    // using ArrayUtils for uint256[];
    using ArrayUtils for uint40[];
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    struct FR {
        bytes32 rule;
        EnumerableSet.UintSet rightholders;
    }

    // struct ruleInfo {
    //     uint8 typeOfDeal;
    //     bool membersEqual;
    //     bool proRata;
    //     bool basedOnPar;
    // }

    // typeOfDeal => FR : right of first refusal
    mapping(uint8 => FR) private _firstRefusals;

    // typeOfDeal => bool
    mapping(uint8 => bool) private _isSubject;

    // ################
    // ##   Event   ##
    // ################

    event SetFirstRefusal(uint8 indexed typeOfDeal, bytes32 rule);

    event AddRightholder(uint8 indexed typeOfDeal, uint40 rightholder);

    event RemoveRightholder(uint8 indexed typeOfDeal, uint40 rightholder);

    event DelFirstRefusal(uint8 indexed typeOfDeal);

    // ################
    // ##  Modifier  ##
    // ################

    modifier beRestricted(uint8 typeOfDeal) {
        require(_isSubject[typeOfDeal], "deal NOT restricted");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createRule(
        uint8 typeOfDeal,
        bool membersEqualOfFR,
        bool proRata,
        bool basedOnPar
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfDeal);
        _sn = _sn.boolToSN(1, membersEqualOfFR);
        _sn = _sn.boolToSN(2, proRata);
        _sn = _sn.boolToSN(3, basedOnPar);

        return _sn.bytesToBytes32();
    }

    function setFirstRefusal(
        uint8 typeOfDeal,
        bool membersEqualOfFR,
        bool proRata,
        bool basedOnPar
    ) external onlyAttorney {
        require(typeOfDeal < 4, "type of deal over flow");

        bytes32 rule = _createRule(
            typeOfDeal,
            membersEqualOfFR,
            proRata,
            basedOnPar
        );

        _firstRefusals[typeOfDeal].rule = rule;
        _isSubject[typeOfDeal] = true;

        emit SetFirstRefusal(typeOfDeal, rule);
    }

    function delFirstRefusal(uint8 typeOfDeal)
        external
        onlyAttorney
        beRestricted(typeOfDeal)
    {
        delete _firstRefusals[typeOfDeal];
        delete _isSubject[typeOfDeal];

        emit DelFirstRefusal(typeOfDeal);
    }

    function addRightholder(uint8 typeOfDeal, uint40 rightholder)
        external
        onlyAttorney
        beRestricted(typeOfDeal)
    {
        FR storage fr = _firstRefusals[typeOfDeal];

        bytes32 rule = fr.rule;

        require(!rule.membersEqualOfFR(), "Members' right are equal");

        if (fr.rightholders.add(uint256(rightholder)))
            emit AddRightholder(typeOfDeal, rightholder);
    }

    function removeRightholder(uint8 typeOfDeal, uint40 acct)
        external
        onlyAttorney
        beRestricted(typeOfDeal)
    {
        FR storage fr = _firstRefusals[typeOfDeal];

        if (fr.rightholders.remove(uint256(acct)))
            emit RemoveRightholder(typeOfDeal, acct);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isSubject(uint8 typeOfDeal) public view onlyUser returns (bool) {
        return _isSubject[typeOfDeal];
    }

    function ruleOfFR(uint8 typeOfDeal)
        public
        view
        beRestricted(typeOfDeal)
        onlyUser
        returns (bytes32)
    {
        return _firstRefusals[typeOfDeal].rule;
    }

    function isRightholder(uint8 typeOfDeal, uint40 acct)
        public
        view
        beRestricted(typeOfDeal)
        onlyUser
        returns (bool)
    {
        FR storage fr = _firstRefusals[typeOfDeal];

        if (fr.rule.membersEqualOfFR()) return _bos.isMember(acct);
        else return fr.rightholders.contains(uint256(acct));
    }

    function rightholders(uint8 typeOfDeal)
        public
        view
        beRestricted(typeOfDeal)
        onlyUser
        returns (uint40[])
    {
        FR storage fr = _firstRefusals[typeOfDeal];

        if (fr.rule.membersEqualOfFR()) return _bos.members();
        else return fr.rightholders.valuesToUint40();
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        public
        view
        onlyUser
        returns (bool)
    {
        require(
            IInvestmentAgreement(ia).isDeal(sn.sequenceOfDeal()),
            "deal not exist"
        );

        return _isSubject[sn.typeOfDeal()];
    }

    function isExempted(address ia, bytes32 sn)
        external
        view
        onlyUser
        returns (bool)
    {
        if (!isTriggered(ia, sn)) return true;
        bytes32 rule = _firstRefusals[sn.typeOfDeal()].rule;

        (uint40[] memory consentParties, ) = _bom.getYea(uint256(ia));

        uint40[] memory signers = ISigPage(ia).parties();

        uint40[] memory agreedParties = consentParties.combine(signers);

        if (rule.membersEqualOfFR())
            return _bos.members().fullyCoveredBy(agreedParties);
        else
            return
                _firstRefusals[sn.typeOfDeal()]
                    .rightholders
                    .valuesToUint40()
                    .fullyCoveredBy(agreedParties);
    }
}
