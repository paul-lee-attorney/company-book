// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

contract SNParserExt {
    // ======== ShareNumber ========

    function class(bytes32 shareNumber) public pure returns (uint16) {
        return uint16(bytes2(shareNumber));
    }

    function ssn(bytes32 shareNumber) public pure returns (uint32) {
        return uint32(bytes4(shareNumber << 16));
    }

    function issueDate(bytes32 shareNumber) public pure returns (uint32) {
        return uint32(bytes4(shareNumber << 48));
    }

    function shareholder(bytes32 shareNumber) public pure returns (uint40) {
        return uint40(bytes5(shareNumber << 80));
    }

    function issuePrice(bytes32 shareNumber) public pure returns (uint64) {
        return uint64(bytes8(shareNumber << 120));
    }

    function preSSN(bytes32 shareNumber) public pure returns (uint32) {
        return uint32(bytes4(shareNumber << 184));
    }

    function hashLockOfBOSLocker(bytes32 sn) public pure returns (bytes16) {
        return bytes16(sn << 120);
    }

    // ======== DealSN ========

    function classOfDeal(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn));
    }

    function seqOfDeal(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 16));
    }

    function typeOfDeal(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[4]);
    }

    function sellerOfDeal(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 40));
    }

    function buyerOfDeal(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 80));
    }

    function groupOfBuyer(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 120));
    }

    function ssnOfDeal(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 136));
    }

    function priceOfDeal(bytes32 sn) public pure returns (uint64) {
        return uint64(bytes8(sn << 168));
    }

    function preSeqOfDeal(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 232));
    }

    // ======== LinkRule ========

    function dragerOfLink(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn));
    }

    function dragerGroupOfLink(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 40));
    }

    function triggerTypeOfLink(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[7]);
    }

    function thresholdOfLink(bytes32 sn) public pure returns (uint64) {
        return uint64(bytes8(sn << 64));
    }

    function proRataOfLink(bytes32 sn) public pure returns (bool) {
        return uint8(sn[16]) == 1;
    }

    function unitPriceOfLink(bytes32 sn) public pure returns (uint64) {
        return uint64(bytes8(sn << 136));
    }

    function roeOfLink(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 200));
    }

    // ======== OptionSN ========

    function typeOfOpt(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[0]);
    }

    function seqOfOpt(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 8));
    }

    function triggerBNOfOpt(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 40));
    }

    function exerciseDaysOfOpt(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[9]);
    }

    function closingDaysOfOpt(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[10]);
    }

    function classOfOpt(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 88));
    }

    function rateOfOpt(bytes32 sn) public pure returns (uint64) {
        return uint64(bytes8(sn << 104));
    }

    function logOperator(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[21]);
    }

    function compOperator_1(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[22]);
    }

    function para_1(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 184));
    }

    function compOperator_2(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[27]);
    }

    function para_2(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 224));
    }

    function checkConditions(
        bytes32 sn,
        uint32 data_1,
        uint32 data_2
    ) public pure returns (bool flag) {
        bool flag_1;
        bool flag_2;

        if (compOperator_1(sn) == 1) flag_1 = data_1 > para_1(sn);
        else if (compOperator_1(sn) == 2) flag_1 = data_1 < para_1(sn);
        else if (compOperator_1(sn) == 3) flag_1 = data_1 >= para_1(sn);
        else if (compOperator_1(sn) == 4) flag_1 = data_1 <= para_1(sn);

        if (compOperator_2(sn) == 1) flag_2 = data_2 > para_2(sn);
        else if (compOperator_2(sn) == 2) flag_2 = data_2 < para_2(sn);
        else if (compOperator_2(sn) == 3) flag_2 = data_2 >= para_2(sn);
        else if (compOperator_2(sn) == 4) flag_2 = data_2 <= para_2(sn);

        if (logOperator(sn) == 1) flag = flag_1 && flag_2;
        else if (logOperator(sn) == 2) flag = flag_1 || flag_2;
        else if (logOperator(sn) == 3) flag = flag_1;
        else if (logOperator(sn) == 4) flag = flag_2;
        else if (logOperator(sn) == 5) flag = flag_1 == flag_2;
        else if (logOperator(sn) == 6) flag = flag_1 != flag_2;
    }

    // ======== Futures ========

    function shortShareNumberOfFt(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn));
    }

    function paidOfFt(bytes32 sn) public pure returns (uint64) {
        return uint64(bytes8(sn << 32));
    }

    function parOfFt(bytes32 sn) public pure returns (uint64) {
        return uint64(bytes8(sn << 96));
    }

    // ======== Pledge ========

    function ssnOfPld(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn));
    }

    function seqOfPld(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 32));
    }

    function createDateOfPld(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 48));
    }

    function pledgorOfPld(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 80));
    }

    function debtorOfPld(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 120));
    }

    // ========= Rules ========

    // ==== Voting Rule ====

    function seqOfRule(bytes32 rule) public pure returns (uint16) {
        return uint16(bytes2(rule));
    }

    function ratioHeadOfVR(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 16));
    }

    function ratioAmountOfVR(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 32));
    }

    function onlyAttendanceOfVR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[6]) == 1;
    }

    function impliedConsentOfVR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[7]) == 1;
    }

    function partyAsConsentOfVR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[8]) == 1;
    }

    function againstShallBuyOfVR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[9]) == 1;
    }

    function reviewDaysOfVR(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[10]);
    }

    function votingDaysOfVR(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[11]);
    }

    function execDaysForPutOptOfVR(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[12]);
    }

    function vetoerOfVR(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 104));
    }

    function vetoer2OfVR(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 144));
    }

    function vetoer3OfVR(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 184));
    }

    function vetoer4OfVR(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 224));
    }

    // ==== FirstRefusal Rule ====

    function typeOfFR(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[2]);
    }

    function membersEqualOfFR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[3]) == 1;
    }

    function proRataOfFR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[4]) == 1;
    }

    function basedOnParOfFR(bytes32 sn) public pure returns (bool) {
        return uint8(sn[5]) == 1;
    }

    // ======== GroupUpdateOrder ========

    function addMemberOfGUO(bytes32 sn) public pure returns (bool) {
        return uint8(sn[0]) == 1;
    }

    function groupNoOfGUO(bytes32 sn) public pure returns (uint16) {
        return uint16(bytes2(sn << 8));
    }

    function memberOfGUO(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 24));
    }

    // ======== MotionSN ========

    function typeOfMotion(bytes32 sn) public pure returns (uint8) {
        return uint8(sn[0]);
    }

    function submitterOfMotion(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 8));
    }

    function proposeBNOfMotion(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 48));
    }

    function votingDeadlineBNOfMotion(bytes32 sn)
        public
        pure
        returns (uint32)
    {
        return uint32(bytes4(sn << 80));
    }

    function weightRegBNOfMotion(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 112));
    }

    function candidateOfMotion(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 144));
    }

    // ======== RegCenter ========

    function fromOfRCLocker(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn));
    }

    function toOfRCLocker(bytes32 sn) public pure returns (uint40) {
        return uint40(bytes5(sn << 40));
    }

    function expireDateOfRCLocker(bytes32 sn) public pure returns (uint32) {
        return uint32(bytes4(sn << 80));
    }

    function hashLockOfRCLocker(bytes32 sn) public pure returns (bytes16) {
        return bytes16(sn << 112);
    }

    function hashTrim(bytes32 hashValue) public pure returns (bytes16) {
        return bytes16(hashValue << 24);
    }
}
