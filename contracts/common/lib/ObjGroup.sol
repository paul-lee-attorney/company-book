/**
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 ***/

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";
import "./SNParser.sol";

library ObjGroup {
    using ArrayUtils for uint40[];
    using ArrayUtils for bytes32[];
    using ArrayUtils for address[];

    using SNParser for bytes32;

    // ======== TimeLine ========

    struct TimeLine {
        mapping(uint8 => uint32) startDateOf;
        uint8 currentState;
    }

    function setState(
        TimeLine storage line,
        uint8 state,
        uint32 startDate
    ) internal {
        line.currentState = state;
        line.startDateOf[state] = startDate;
    }

    function pushToNextState(TimeLine storage line, uint32 nextKeyDate)
        internal
    {
        line.currentState++;
        line.startDateOf[line.currentState] = nextKeyDate;
    }

    function backToPrevState(TimeLine storage line) internal {
        require(line.currentState > 0, "currentState overflow");
        line.startDateOf[line.currentState] = 0;
        line.currentState--;
    }
}
