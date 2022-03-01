/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";
import "../config/DraftSetting.sol";

// import "./interfaces/IVotingRules.sol";

contract VotingRules is BOSSetting, DraftSetting {
    struct Rule {
        uint256 ratioHead;
        uint256 ratioAmount;
        bool onlyVoted;
        bool impliedConsent;
        bool againstShallBuy;
        uint8 reconsiderDays;
    }

    bool private _basedOnParValue; //false-on PaidIn; true- ParValue

    uint8 private _votingDays;

    // typeOfRule => Rule : 0-ST(internal) 1-CI 2-ST(to 3rd Party)
    mapping(uint8 => Rule) private _rules;

    // ################
    // ##   Event    ##
    // ################

    event SetRule(
        uint8 typeOfRule,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyVoted,
        bool impliedConsent,
        bool againstShallBuy,
        uint8 reconsiderDays
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
        bool onlyVoted,
        bool impliedConsent,
        bool againstShallBuy,
        uint8 reconsiderDays
    ) external onlyAttorney typeAllowed(typeOfRule) {
        Rule storage rule = _rules[typeOfRule];

        rule.ratioHead = ratioHead;
        rule.ratioAmount = ratioAmount;
        rule.onlyVoted = onlyVoted;
        rule.impliedConsent = impliedConsent;
        rule.againstShallBuy = againstShallBuy;
        rule.reconsiderDays = reconsiderDays;

        emit SetRule(
            typeOfRule,
            ratioHead,
            ratioAmount,
            onlyVoted,
            impliedConsent,
            againstShallBuy,
            reconsiderDays
        );
    }

    function setCommonRules(uint8 votingDays, bool basedOnParValue)
        external
        onlyAttorney
    {
        require(votingDays > 0, "不应小于零");

        _votingDays = votingDays;
        _basedOnParValue = basedOnParValue;

        emit SetCommonRules(votingDays, basedOnParValue);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getVotingDays() public view returns (uint8) {
        return _votingDays;
    }

    function basedOnParValue() public view returns (bool) {
        return _basedOnParValue;
    }

    function getRule(uint8 typeOfRule)
        public
        view
        typeAllowed(typeOfRule)
        returns (
            uint256 ratioHead,
            uint256 ratioAmount,
            bool onlyVoted,
            bool impliedConsent,
            bool againstShallBuy,
            uint8 reconsiderDays
        )
    {
        ratioHead = _rules[typeOfRule].ratioHead;
        ratioAmount = _rules[typeOfRule].ratioAmount;
        onlyVoted = _rules[typeOfRule].onlyVoted;
        impliedConsent = _rules[typeOfRule].impliedConsent;
        againstShallBuy = _rules[typeOfRule].againstShallBuy;
        reconsiderDays = _rules[typeOfRule].reconsiderDays;
    }
}
