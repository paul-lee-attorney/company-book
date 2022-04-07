pragma solidity ^0.4.24;

library VotingRuleParser {
    function ratioHead(bytes32 sn) internal pure returns (uint256 ratioHead) {
        ratioHead = uint256(bytes2(sn));
    }

    function ratioAmount(bytes32 sn)
        internal
        pure
        returns (uint256 ratioAmount)
    {
        ratioAmount = uint256(bytes2(sn << 16));
    }

    function onlyAttendance(bytes32 sn)
        internal
        pure
        returns (bool onlyAttendance)
    {
        onlyAttendance = uint8(sn[4]) == 1;
    }

    function impliedConsent(bytes32 sn)
        internal
        pure
        returns (bool impliedConsent)
    {
        impliedConsent = uint8(sn[5]) == 1;
    }

    function againstShallBuy(bytes32 sn)
        internal
        pure
        returns (bool againstShallBuy)
    {
        againstShallBuy = uint8(sn[6]) == 1;
    }
}
