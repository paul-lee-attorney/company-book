pragma solidity ^0.4.24;

library VotingRuleParser {
    function ratioHead(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes2(sn));
    }

    function ratioAmount(bytes32 sn) internal pure returns (uint256) {
        return uint256(bytes2(sn << 16));
    }

    function onlyAttendance(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[4]) == 1;
    }

    function impliedConsent(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[5]) == 1;
    }

    function againstShallBuy(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[6]) == 1;
    }

    function basedOnParValue(bytes32 sn) internal pure returns (bool) {
        return uint8(sn[7]) == 1;
    }

    function votingDays(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[8]);
    }

    function execDaysForPutOpt(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[9]);
    }

    function typeOfVote(bytes32 sn) internal pure returns (uint8) {
        return uint8(sn[10]);
    }
}
