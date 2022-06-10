/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library EnumsRepo {
    enum TermTitle {
        LOCK_UP,
        ANTI_DILUTION,
        FIRST_REFUSAL,
        GROUPS_UPDATE,
        DRAG_ALONG,
        TAG_ALONG,
        OPTIONS
    }

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        PreEmptive,
        ShareTransferExt,
        TagAlong,
        DragAlong,
        ShareTransferInt,
        FirstRefusal,
        FreeGift
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

    enum BODStates {
        ZeroPoint,
        Created,
        Circulated,
        Established,
        Proposed,
        Voted,
        Exercised
    }

    // enum BOAStates {
    //     ZeroPoint,
    //     Created,
    //     Circulated,
    //     Proposed,
    //     Voted,
    //     Exercised
    // }

    enum ActionType {
        CAPITAL_INCREASE,
        SHARE_TRANSFER,
        PRE_EMPTIVE,
        FIRST_REFUSAL,
        DRAG_ALONG,
        TAG_ALONG,
        SET_PLEDGE,
        RELEASE_PLEDGE,
        ANTI_DILUTION,
        ANNUAL_REPORT,
        PUT_OPTION,
        CALL_OPTION,
        VALUE_ADJUST,
        LIQUIDATION,
        LIQUID_PRIORITY,
        LOCKUP_EXEMPT,
        ANTIDILUTION_EXEMPT,
        CONVENE_GM
    }

    enum TermState {
        DRAFTING,
        VOTING,
        REJECTED,
        EFFECTIVE,
        REVOKED
    }

    enum MotionState {
        PROPOSED,
        DISTRIBUTED,
        PASSED,
        REJECTED
    }
}
