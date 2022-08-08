/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./IInvestmentAgreement.sol";
import "./IBookOfIA.sol";
import "./IFirstRefusalDeals.sol";

import "../../common/components/DocumentsRepo.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/IBookSetting.sol";

contract BookOfIA is IBookOfIA, DocumentsRepo {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // ==== FRDeals ====

    // ia => frd
    mapping(address => address) private _frDeals;

    // ==== MockDeals ====

    // ia => mockResults
    mapping(address => address) private _mockResults;

    //#################
    //##  Write I/O  ##
    //#################

    function circulateIA(address ia, uint40 submitter) external onlyManager(1) {
        bytes32 rule = _getSHA().votingRules(typeOfIA(ia));

        circulateDoc(ia, rule, submitter);
    }

    function createFRDeals(address ia, uint40 creator)
        external
        onlyKeeper
        returns (address frd)
    {
        if (_frDeals[ia] == address(0)) {
            frd = createDoc(1, creator);
            IAccessControl(frd).init(
                this,
                this,
                _rc,
                uint8(EnumsRepo.RoleOfUser.FirstRefusalDeals),
                _rc.entityNo(this)
            );
            IBookSetting(frd).setIA(ia);
            copyRoleTo(KEEPERS, frd);
        }
    }

    function createMockResults(address ia, uint40 creator)
        external
        onlyKeeper
        returns (address mock)
    {
        if (_mockResults[ia] == address(0)) {
            mock = createDoc(2, creator);
            IAccessControl(mock).init(
                msg.sender,
                this,
                _rc,
                uint8(EnumsRepo.RoleOfUser.MockResults),
                _rc.entityNo(this)
            );
            IBookSetting(mock).setIA(ia);
            copyRoleTo(KEEPERS, mock);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    function typeOfIA(address ia) public view returns (uint8 output) {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;
        uint8[3] memory signal;

        while (len > 0) {
            uint8 typeOfDeal = dealsList[len - 1].typeOfDeal();
            len--;

            (, , , uint8 state, ) = IInvestmentAgreement(ia).getDeal(
                dealsList[len - 1].sequence()
            );

            if (state == uint8(EnumsRepo.StateOfDeal.Terminated)) continue;

            if (
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease) ||
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.PreEmptive)
            ) signal[0] = 1;
            else if (
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.ShareTransferExt) ||
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.TagAlong) ||
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.DragAlong)
            ) signal[1] = 2;
            else if (
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.ShareTransferInt) ||
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.FirstRefusal) ||
                typeOfDeal == uint8(EnumsRepo.TypeOfDeal.FreeGift)
            ) signal[2] = 3;
        }
        // 协议类别计算
        uint8 sumOfSignal = signal[0] + signal[1] + signal[2];
        output = sumOfSignal == 3 ? signal[2] == 0 ? 7 : 3 : sumOfSignal;
    }

    function frDealsOfIA(address ia) external view returns (address) {
        return _frDeals[ia];
    }

    function mockResultsOfIA(address ia) external view returns (address) {
        return _mockResults[ia];
    }
}
