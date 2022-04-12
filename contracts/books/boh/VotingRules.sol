/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/config/BOSSetting.sol";
import "../../common/config/DraftSetting.sol";

import "../../common/lib/serialNumber/SNFactory.sol";

contract VotingRules_ is BOSSetting, DraftSetting {
    using SNFactory for bytes;

    // struct snInfo {
    //     uint ratioHead;
    //     uint ratioAmount;
    //     bool onlyAttendance;
    //     bool impliedConsent;
    //     bool againstShallBuy;
    //     bool basedOnParValue; //default: false - based on PaidInAmount; true- ParValue
    //     uint8 votingDays; //default: 30 natrual days
    //     uint8 execDaysForPutOpt; //default: 7 natrual days
    //     uint8 turnOverDaysForFuture; //default: 7 natrual days
    // }

    // typeOfRule => Rule : 0-ST(internal) 1-CI 2-ST(to 3rd Party)
    bytes32[3] public rules;

    constructor() {
        // votingDays = 30; // default 30 days as per Company Law Act

        // default for Capital Increase : (10进制) 0000 6666 00 00 00 00 30 00
        rules[
            1
        ] = 0x004242000000001e0000000000000000000000000000000000000000000000;

        // default for Share Transfer : (10进制) 0000 5000 00 01 01 00 30 07 07
        rules[
            2
        ] = 0x003200000101001e0707000000000000000000000000000000000000000000;
    }

    // ################
    // ##   Event    ##
    // ################

    event SetRule(uint8 typeOfRule, bytes32 sn);

    // event SetCommonRules(uint8 votingDays, bool basedOnParValue);

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
        bool againstShallBuy,
        bool basedOnParValue,
        uint8 votingDays,
        uint8 execDaysForPutOpt,
        uint8 turnOverDaysForFuture
    ) private returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.intToSN(0, ratioHead, 2);
        _sn = _sn.intToSN(2, ratioAmount, 2);
        _sn = _sn.boolToSN(4, onlyAttendance);
        _sn = _sn.boolToSN(5, impliedConsent);
        _sn = _sn.boolToSN(6, againstShallBuy);
        _sn = _sn.boolToSN(7, basedOnParValue);
        _sn[8] = bytes1(votingDays);
        _sn[9] = bytes1(execDaysForPutOpt);
        _sn[10] = bytes1(turnOverDaysForFuture);

        sn = _sn.bytesToBytes32();
    }

    function setRule(
        uint8 typeOfRule,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy,
        bool basedOnParValue,
        uint8 votingDays,
        uint8 execDaysForPutOpt,
        uint8 turnOverDaysForFuture
    ) external onlyAttorney typeAllowed(typeOfRule) {
        require(votingDays > 0, "ZERO votingDays");

        bytes32 sn = _createRule(
            ratioHead,
            ratioAmount,
            onlyAttendance,
            impliedConsent,
            againstShallBuy,
            basedOnParValue,
            votingDays,
            execDaysForPutOpt,
            turnOverDaysForFuture
        );

        rules[typeOfRule] = sn;

        emit SetRule(typeOfRule, sn);
    }
}
