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
        Executed,
        Proposed,
        Voted,
        Exercised
    }

    enum TermState {
        DRAFTING,
        VOTING,
        REJECTED,
        EFFECTIVE,
        REVOKED
    }

    enum StateOfMotion {
        Pending,
        Proposed,
        Passed,
        Rejected_NotToBuy,
        Rejected_ToBuy
    }

    enum TypeOfOption {
        Call_Price,
        Put_Price,
        Call_ROE,
        Put_ROE,
        Call_PriceAndConditions,
        Put_PriceAndConditions,
        Call_ROEAndConditions,
        Put_ROEAndConditions
    }

    enum StateOfOption {
        Pending,
        Issued,
        Executed,
        Futured,
        Pledged,
        Closed,
        Revoked,
        Expired
    }

    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

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
}
