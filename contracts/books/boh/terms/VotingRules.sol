/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../../common/config/DraftSetting.sol";

import "../../../common/lib/serialNumber/SNFactory.sol";

contract VotingRules is DraftSetting {
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
    //     uint8 typeOfVote;
    // }

    // typeOfVote => Rule : 1-CI 2-ST(to 3rd Party) 3-ST(to otherMember) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    bytes32[8] public votingRules;

    constructor() public {
        // votingDays = 30; // default 30 days as per Company Law Act

        // default for Capital Increase : (10进制) 0000 6666 00 00 00 00 30 00  01
        votingRules[
            1
        ] = 0x004242000000001e0001000000000000000000000000000000000000000000;

        votingRules[
            4
        ] = 0x004242000000001e0004000000000000000000000000000000000000000000;

        votingRules[
            6
        ] = 0x004242000000001e0706000000000000000000000000000000000000000000;

        votingRules[
            7
        ] = 0x004242000000001e0707000000000000000000000000000000000000000000;

        // default for Share Transfer : (10进制) 0000 5000 00 01 01 00 30 07 02
        votingRules[
            2
        ] = 0x003200000101001e0702000000000000000000000000000000000000000000;

        votingRules[
            3
        ] = 0x00000000000000000003000000000000000000000000000000000000000000;

        votingRules[
            5
        ] = 0x003200000101001e0705000000000000000000000000000000000000000000;
    }

    // ################
    // ##   Event    ##
    // ################

    event SetRule(uint8 typeOfVote, bytes32 sn);

    // ################
    // ##  Modifier  ##
    // ################

    modifier typeAllowed(uint8 typeOfVote) {
        require(typeOfVote < 8, "typeOfVote overflow");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setRule(
        uint8 typeOfVote,
        uint256 ratioHead,
        uint256 ratioAmount,
        bool onlyAttendance,
        bool impliedConsent,
        bool againstShallBuy,
        bool basedOnParValue,
        uint8 votingDays,
        uint8 execDaysForPutOpt
    ) external onlyAttorney typeAllowed(typeOfVote) {
        require(votingDays > 0, "ZERO votingDays");

        bytes memory _sn = new bytes(32);

        _sn = _sn.intToSN(0, ratioHead, 2);
        _sn = _sn.intToSN(2, ratioAmount, 2);
        _sn = _sn.boolToSN(4, onlyAttendance);
        _sn = _sn.boolToSN(5, impliedConsent);
        _sn = _sn.boolToSN(6, againstShallBuy);
        _sn = _sn.boolToSN(7, basedOnParValue);
        _sn[8] = bytes1(votingDays);
        _sn[9] = bytes1(execDaysForPutOpt);
        _sn[10] = bytes1(typeOfVote);

        votingRules[typeOfVote] = _sn.bytesToBytes32();

        emit SetRule(typeOfVote, votingRules[typeOfVote]);
    }
}
