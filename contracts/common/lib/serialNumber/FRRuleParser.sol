pragma solidity ^0.4.24;

library FRRuleParser {
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
}
