/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../boa/interfaces/IAgreement.sol";

import "../../../common/config/BOSSetting.sol";
import "../../../common/config/BOMSetting.sol";
import "../../../common/config/DraftSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/serialNumber/SNFactory.sol";
import "../../../common/lib/serialNumber/FRRuleParser.sol";
import "../../../common/lib/serialNumber/DealSNParser.sol";

import "../../../common/components/interfaces/ISigPage.sol";

// import "../../../common/interfaces/IMotion.sol";

contract FirstRefusal is BOSSetting, BOMSetting, DraftSetting {
    // using ArrayUtils for uint256[];
    using ArrayUtils for address[];
    using SNFactory for bytes;
    using FRRuleParser for bytes32;
    using DealSNParser for bytes32;

    struct FR {
        bytes32 rule;
        mapping(address => bool) isRightholder;
        address[] rightholders;
    }

    // struct ruleInfo {
    //     uint8 typeOfDeal;
    //     bool membersEqual;
    //     bool proRata;
    //     bool basedOnPar;
    // }

    // typeOfDeal => FR : right of first refusal
    mapping(uint8 => FR) public FRs;

    // typeOfDeal => bool
    mapping(uint8 => bool) public isSubject;

    // ################
    // ##   Event   ##
    // ################

    event SetFirstRefusal(uint8 indexed typeOfDeal, bytes32 rule);

    event AddRightholder(uint8 indexed typeOfDeal, address rightholder);

    event RemoveRightholder(uint8 indexed typeOfDeal, address rightholder);

    event DelFirstRefusal(uint8 indexed typeOfDeal);

    // ################
    // ##  Modifier  ##
    // ################

    modifier beRestricted(uint8 typeOfDeal) {
        require(isSubject[typeOfDeal], "deal NOT restricted");
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

        FRs[typeOfDeal].rule = rule;
        isSubject[typeOfDeal] = true;

        emit SetFirstRefusal(typeOfDeal, rule);
    }

    function delFirstRefusal(uint8 typeOfDeal)
        external
        onlyAttorney
        beRestricted(typeOfDeal)
    {
        delete FRs[typeOfDeal];
        delete isSubject[typeOfDeal];

        emit DelFirstRefusal(typeOfDeal);
    }

    function addRightholder(uint8 typeOfDeal, address rightholder)
        external
        onlyAttorney
        beRestricted(typeOfDeal)
    {
        FR storage fr = FRs[typeOfDeal];

        bytes32 rule = fr.rule;

        require(!rule.membersEqualOfFR(), "Members' right are equal");

        fr.isRightholder[rightholder] = true;
        fr.rightholders.push(rightholder);

        emit AddRightholder(typeOfDeal, rightholder);
    }

    function removeRightholder(uint8 typeOfDeal, address acct)
        external
        onlyAttorney
        beRestricted(typeOfDeal)
    {
        FR storage fr = FRs[typeOfDeal];

        require(fr.isRightholder[acct], "NOT a rightholder");

        delete fr.isRightholder[acct];

        fr.rightholders.removeByValue(acct);

        emit RemoveRightholder(typeOfDeal, acct);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function ruleOfFR(uint8 typeOfDeal)
        public
        view
        beRestricted(typeOfDeal)
        returns (bytes32)
    {
        return FRs[typeOfDeal].rule;
    }

    function isRightholder(uint8 typeOfDeal, address acct)
        public
        view
        beRestricted(typeOfDeal)
        returns (bool)
    {
        FR storage fr = FRs[typeOfDeal];

        if (fr.rule.membersEqualOfFR()) return _bos.isMember(acct);
        else return fr.isRightholder[acct];
    }

    function rightholders(uint8 typeOfDeal)
        public
        view
        beRestricted(typeOfDeal)
        returns (address[])
    {
        FR storage fr = FRs[typeOfDeal];

        if (fr.rule.membersEqualOfFR()) return _bos.membersList();
        else return fr.rightholders;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        public
        view
        onlyKeeper
        returns (bool)
    {
        require(IAgreement(ia).isDeal(sn.sequenceOfDeal()), "deal not exist");

        return isSubject[sn.typeOfDeal()];
    }

    function isExempted(address ia, bytes32 sn)
        external
        view
        onlyKeeper
        returns (bool)
    {
        if (!isTriggered(ia, sn)) return true;

        bytes32 rule = FRs[sn.typeOfDeal()].rule;

        (address[] memory consentParties, ) = _bom.getYea(ia);

        address[] memory signers = ISigPage(ia).signers();

        address[] memory agreedParties = consentParties.combine(signers);

        if (rule.membersEqualOfFR())
            return _bos.membersList().fullyCoveredBy(agreedParties);
        else
            return
                FRs[sn.typeOfDeal()].rightholders.fullyCoveredBy(agreedParties);
    }
}
