/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/BOSSetting.sol";
import "../common/config/DraftSetting.sol";

import "../common/lib/serialNumber/SNFactory.sol";

contract VotingRules_ is BOSSetting, DraftSetting {
    using SNFactory for bytes;

    bool public basedOnParValue; //default: false - based on PaidInAmount; true- ParValue

    uint8 public votingDays; //default: 30 natrual days

    // struct snInfo {
    //     uint256 ratioHead;
    //     uint256 ratioAmount;
    //     bool onlyAttendance;
    //     bool impliedConsent;
    //     bool againstShallBuy;
    // }

    // typeOfRule => Rule : 0-ST(internal) 1-CI 2-ST(to 3rd Party)
    bytes32[3] public rules;

    constructor() {
        votingDays = 30; // default 30 days as per Company Law Act

        // default for Capital Increase : (10进制) 0000 6666 00 00 00
        rules[
            1
        ] = 0x00424200000000000000000000000000000000000000000000000000000000;

        // default for Share Transfer : (10进制) 0000 5000 00 01 01
        rules[
            2
        ] = 0x00320000010100000000000000000000000000000000000000000000000000;
    }

    // ################
    // ##   Event    ##
    // ################

    event SetRule(uint8 typeOfRule, bytes32 sn);

    event SetCommonRules(uint8 votingDays, bool basedOnParValue);

    // ################
    // ##  Modifier  ##
    // ################

    modifier typeAllowed(uint8 typeOfRule) {
        require(typeOfRule < 3, "typeOfRule overflow");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createRule(
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy
    ) private returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.intToSN(0, ratioHead, 2);
        _sn = _sn.intToSN(2, ratioAmount, 2);
        _sn[4] = bytes1(onlyAttendance);
        _sn[5] = bytes1(impliedConsent);
        _sn[6] = bytes1(againstShallBuy);

        sn = _sn.bytesToBytes32();
    }

    function setRule(
        uint8 typeOfRule,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy
    ) external onlyAttorney typeAllowed(typeOfRule) {
        bytes32 rule = _createRule(
            ratioHead,
            ratioAmount,
            onlyAttendance,
            impliedConsent,
            againstShallBuy
        );

        rules[typeOfRule] = rule;

        emit SetRule(typeOfRule, rule);
    }

    function setCommonRules(uint8 _votingDays, bool _basedOnParValue)
        external
        onlyAttorney
    {
        require(_votingDays > 0, "不应小于零");

        votingDays = _votingDays;
        basedOnParValue = _basedOnParValue;

        emit SetCommonRules(_votingDays, _basedOnParValue);
    }
}
