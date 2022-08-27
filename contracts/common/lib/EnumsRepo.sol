/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library EnumsRepo {
    enum TitleOfManagers {
        Owner,
        Bookeeper,
        GeneralCounsel
    }
    enum NameOfBook {
        BOA,
        BOD,
        BOH,
        BOM,
        BOO,
        BOP,
        BOS,
        BOSCal
    }

    enum TypeOfVertex {
        ZeroPoint,
        EOA,
        Company,
        Group
    }

    enum TypeOfEntity {
        ZeroPoint,
        EOA,
        Company
    }

    enum TypeOfConnection {
        EquityInvestment,
        Director,
        VirtualGroup
    }

    enum RoleOfUser {
        ZeroPoint, //               0
        EOA, //                     1
        BookOfShares, //            2
        BookOfMotions, //           3
        BookOfDirectors, //         4
        BookOfConcerted, //         5
        BookOfIA, //                6
        BookOfSHA, //               7
        BookOfOptions, //           8
        BookOfPledges, //           9
        GeneralKeeper, //           10
        BOAKeeper, //               11
        BODKeeper, //               12
        BOHKeeper, //               13
        BOMKeeper, //               14
        BOOKeeper, //               15
        BOPKeeper, //               16
        BOSKeeper, //               17
        SHAKeeper, //               18
        BOSCalculator, //           19
        InvestmentAgreement, //     20
        FirstRefusalDeals, //       21
        MockResults, //             22
        ShareholdersAgreement, //   23
        SHATerms, //                24
        EndPoint //                 25
    }

    enum TermTitle {
        ZeroPoint,
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
        Executed
    }

    enum TermState {
        DRAFTING,
        VOTING,
        REJECTED,
        EFFECTIVE,
        REVOKED
    }

    enum AttitudeOfVote {
        ZeroPoint,
        Support,
        Against,
        Abstain
    }

    enum StateOfMotion {
        Pending,
        Proposed,
        Passed,
        Rejected,
        Rejected_NotToBuy,
        Rejected_ToBuy,
        Executed
    }

    enum TypeOfVoting {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STI,
        STE_STI,
        CI_STE_STI,
        CI_STE,
        ElectDirector,
        ReviseAOA,
        NomalAction,
        SpecialAction
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

    enum TitleOfDirectors {
        ZeroPoint,
        Chairman,
        ViceChairman,
        Director
    }
}
