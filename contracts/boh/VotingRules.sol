/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";
import "../config/DraftSetting.sol";

contract VotingRules is BOSSetting, DraftSetting {
    struct Rule {
        uint256 ratioHead;
        uint256 ratioAmount;
        bool onlyAttendance;
        bool impliedConsent;
        bool againstShallBuy;
    }

    bool public basedOnParValue; //default: false - based on PaidInAmount; true- ParValue

    uint8 public votingDays; //default: 30 natrual days

    // typeOfRule => Rule : 0-ST(internal) 1-CI 2-ST(to 3rd Party)
    mapping(uint8 => Rule) private _rules;

    constructor() {
        votingDays = 30; // default 30 days as per Company Law Act

        // default for Capital Increase
        _rules[1].ratioAmount = 6666;

        // default for Share Transfer
        _rules[2].ratioAmount = 5000;
        _rules[2].impliedConsent = true;
        _rules[2].againstShallBuy = true;
    }

    // ################
    // ##   Event    ##
    // ################

    event SetRule(
        uint8 typeOfRule,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy
    );

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

    function setRule(
        uint8 typeOfRule,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy
    ) external onlyAttorney typeAllowed(typeOfRule) {
        Rule storage rule = _rules[typeOfRule];

        rule.ratioHead = ratioHead;
        rule.ratioAmount = ratioAmount;
        rule.onlyAttendance = onlyAttendance;
        rule.impliedConsent = impliedConsent;
        rule.againstShallBuy = againstShallBuy;

        emit SetRule(
            typeOfRule,
            ratioHead,
            ratioAmount,
            onlyAttendance,
            impliedConsent,
            againstShallBuy
        );
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

    // ################
    // ##  查询接口  ##
    // ################

    function getRule(uint8 typeOfRule)
        public
        view
        typeAllowed(typeOfRule)
        returns (
            uint256 ratioHead,
            uint256 ratioAmount,
            bool onlyAttendance,
            bool impliedConsent,
            bool againstShallBuy
        )
    {
        ratioHead = _rules[typeOfRule].ratioHead;
        ratioAmount = _rules[typeOfRule].ratioAmount;
        onlyAttendance = _rules[typeOfRule].onlyAttendance;
        impliedConsent = _rules[typeOfRule].impliedConsent;
        againstShallBuy = _rules[typeOfRule].againstShallBuy;
    }
}
