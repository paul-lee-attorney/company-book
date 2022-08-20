/**
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 ***/

pragma solidity ^0.4.24;

library SNParser {
    // ======== EdgeOfGraph ========

    function from(uint88 edge) internal pure returns (uint40) {
        return uint40(edge >> 40);
    }

    function to(uint88 edge) internal pure returns (uint40) {
        return uint40(edge);
    }

    function typeOfEdge(uint88 edge) internal pure returns (uint8) {
        return uint8(edge >> 80);
    }

    // ======== Bytes32Que ========
    function insertToQue(bytes32 sn, bytes32[] storage que)
        internal
        returns (uint256)
    {
        uint256 len = que.length;
        que.push(sn);

        while (len > 0) {
            if (que[len - 1] <= que[len]) break;
            (que[len - 1], que[len]) = (que[len], que[len - 1]);
            len--;
        }

        return len;
    }

    // ======== ShareNumber ========

    function class(bytes32 shareNumber) internal pure returns (uint8) {
        return uint8(shareNumber[0]);
    }

    function ssn(bytes32 shareNumber) internal pure returns (uint32) {
        return uint32(bytes4(shareNumber << 8));
    }

    function issueDate(bytes32 shareNumber) internal pure returns (uint32) {
        return uint32(bytes4(shareNumber << 40));
    }

    function shareholder(bytes32 shareNumber) internal pure returns (uint40) {
        return uint40(bytes5(shareNumber << 72));
    }

    function preSSN(bytes32 shareNumber) internal pure returns (uint32) {
        return uint32(bytes4(shareNumber << 112));
    }

    // ======== DealSN ========

    function classOfDeal(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function typeOfDeal(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[1]);
    }

    function sequence(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 16));
    }

    function buyerOfDeal(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 32));
    }

    function groupOfBuyer(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 72));
    }

    function ssnOfDeal(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 88));
    }

    function preSeqOfDeal(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 120));
    }

    // ======== DocSN ========

    function typeOfDoc(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function createDateOfDoc(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 40));
    }

    function creatorOfDoc(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 72));
    }

    // ======== FirstRefusalRule ========

    function typeOfFR(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function membersEqualOfFR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[1]) == 1;
    }

    function proRataOfFR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[2]) == 1;
    }

    function basedOnParOfFR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[3]) == 1;
    }

    // ======== GroupUpdateOrder ========

    function addMemberOfGUO(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[0]) == 1;
    }

    function groupNoOfGUO(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 8));
    }

    function memberOfGUO(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 24));
    }

    // ======== LinkRule ========

    function dragerOfLink(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn));
    }

    function triggerTypeOfLink(bytes32 sn) internal pure returns (uint8) {
        return uint8(bytes1(sn << 16));
    }

    function thresholdOfLink(bytes32 sn) internal pure returns (uint64) {
        return uint64(bytes4(sn << 24));
    }

    function proRataOfLink(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[4]) == 1;
    }

    function unitPriceOfLink(bytes32 sn) internal pure returns (uint64) {
        return uint64(bytes4(sn << 64));
    }

    function roeOfLink(bytes32 sn) internal pure returns (uint64) {
        return uint64(bytes4(sn << 96));
    }

    // ======== OptionSN ========

    function typeOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function triggerDateOfOpt(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 40));
    }

    function exerciseDaysOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[9]);
    }

    function closingDaysOfOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[10]);
    }

    function rateOfOpt(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 88));
    }

    function logOperator(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[15]);
    }

    function compOperator_1(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[16]);
    }

    function para_1(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 136));
    }

    function compOperator_2(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[21]);
    }

    function para_2(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 176));
    }

    function checkConditions(
        bytes32 sn,
        uint32 data_1,
        uint32 data_2
    ) internal pure returns (bool) {
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

        if (logOperator(sn) == 1) return flag_1 && flag_2;
        else if (logOperator(sn) == 2) return flag_1 || flag_2;
        else if (logOperator(sn) == 3) return flag_1;
        else if (logOperator(sn) == 4) return flag_2;
        else if (logOperator(sn) == 5) return flag_1 == flag_2;
        else if (logOperator(sn) == 6) return flag_1 != flag_2;
    }

    // ======== Futures ========

    function shortShareNumberOfFt(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn));
    }

    function parValueOfFt(bytes32 sn) internal pure returns (uint64) {
        return uint64(bytes8(sn << 32));
    }

    function paidParOfFt(bytes32 sn) internal pure returns (uint64) {
        return uint64(bytes8(sn << 96));
    }

    // ======== Pledge ========

    function typeOfPledge(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function createDateOfPledge(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 40));
    }

    function shortShareNumberOfPledge(bytes32 sn)
        internal
        pure
        returns (uint32)
    {
        return uint32(bytes4(sn << 72));
    }

    function pledgorOfPledge(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 104));
    }

    function debtorOfPledge(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 144));
    }

    // ========= VotingRule ========

    function ratioHeadOfVR(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn));
    }

    function ratioAmountOfVR(bytes32 sn) internal pure returns (uint16) {
        return uint16(bytes2(sn << 16));
    }

    function onlyAttendanceOfVR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[4]) == 1;
    }

    function impliedConsentOfVR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[5]) == 1;
    }

    function partyAsConsentOfVR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[6]) == 1;
    }

    function againstShallBuyOfVR(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[7]) == 1;
    }

    function reviewDaysOfVR(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[8]);
    }

    function votingDaysOfVR(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[9]);
    }

    function execDaysForPutOptOfVR(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[10]);
    }

    function typeOfVoteOfVR(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[11]);
    }

    function vetoHolderOfVR(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 96));
    }

    // ======== MotionSN ========

    function typeOfMotion(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[0]);
    }

    function submitterOfMotion(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 8));
    }

    function proposeDateOfMotion(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 48));
    }

    function votingDeadlineOfMotion(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 80));
    }

    function weightRegBlockOfMotion(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes4(sn << 112));
    }

    function candidateOfMotion(bytes32 sn) internal pure returns (uint40) {
        return uint40(bytes5(sn << 144));
    }

    // ======== AntiDilution ========
    function priceOfMark(bytes32 sn) internal pure returns (uint32) {
        return uint32(bytes29(sn << 24));
    }

    function classOfMark(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[2]);
    }
}
