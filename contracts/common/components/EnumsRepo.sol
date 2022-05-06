/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

contract EnumsRepo {
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

    enum TermTitle {
        LOCK_UP,
        ANTI_DILUTION,
        PRE_EMPTIVE,
        FIRST_REFUSAL,
        GROUP_UPDATE,
        DRAG_ALONG,
        TAG_ALONG,
        PUT_OPTION,
        CALL_OPTION,
        LIQUIDATION_PREFERENCE,
        VALUATION_ADJUSTMENT,
        ORDINARY_ISSUES,
        SPECIAL_ISSUES,
        GENERAL_INFO,
        BOARD,
        VOTING_RULES
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
