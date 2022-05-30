/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library Timeline {
    struct Line {
        mapping(uint8 => uint32) startDateOf;
        uint8 currentState;
    }

    function pushToNextState(Line storage line, uint32 nextKeyDate) internal {
        line.currentState++;
        line.startDateOf[line.currentState] = nextKeyDate;
    }

    function backToPrevState(Line storage line) internal {
        require(line.currentState > 0, "currentState overflow");
        line.startDateOf[line.currentState] = 0;
        line.currentState--;
    }
}
