// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./InvestmentAgreement.sol";
import "./IInvestmentAgreement.sol";
import "./IBookOfIA.sol";

import "../../common/components/DocumentsRepo.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/IBookSetting.sol";

contract BookOfIA is
    IBookOfIA,
    SHASetting,
    BOSSetting,
    ROMSetting,
    DocumentsRepo
{
    using SNParser for bytes32;

    // ia => frd
    mapping(address => address) private _frDeals;

    // ia => mockResults
    mapping(address => address) private _mockResults;

    //#################
    //##  Write I/O  ##
    //#################

    function circulateIA(address ia) external onlyKeeper {
        bytes32 rule = _getSHA().votingRules(typeOfIA(ia));

        circulateDoc(ia, rule);
    }

    function createFRDeals(address ia, uint40 creator)
        external
        onlyDK
        returns (address frd)
    {
        if (_frDeals[ia] == address(0)) {
            frd = createDoc(1, creator);
        }
    }

    function createMockResults(address ia)
        external
        onlyDK
        returns (address mock)
    {
        uint40 creator = _msgSender();

        if (_mockResults[ia] == address(0)) {
            mock = createDoc(2, creator);
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
            bytes32 sn = dealsList[len - 1];
            len--;

            uint8 typeOfDeal = sn.typeOfDeal();

            (, , , uint8 state, ) = IInvestmentAgreement(ia).getDeal(
                sn.sequence()
            );

            if (state == uint8(InvestmentAgreement.StateOfDeal.Terminated))
                continue;

            if (
                typeOfDeal ==
                uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease) ||
                typeOfDeal == uint8(InvestmentAgreement.TypeOfDeal.PreEmptive)
            ) signal[0] = 1;
            else if (
                typeOfDeal ==
                uint8(InvestmentAgreement.TypeOfDeal.ShareTransferExt) ||
                typeOfDeal == uint8(InvestmentAgreement.TypeOfDeal.TagAlong) ||
                typeOfDeal == uint8(InvestmentAgreement.TypeOfDeal.DragAlong)
            ) signal[1] = 2;
            else if (
                typeOfDeal ==
                uint8(InvestmentAgreement.TypeOfDeal.ShareTransferInt) ||
                typeOfDeal ==
                uint8(InvestmentAgreement.TypeOfDeal.FirstRefusal) ||
                typeOfDeal == uint8(InvestmentAgreement.TypeOfDeal.FreeGift)
            ) signal[2] = 3;
        }
        // 协议类别计算
        uint8 sumOfSignal = signal[0] + signal[1] + signal[2];

        output = sumOfSignal;
        if (sumOfSignal == 3 && signal[2] == 0) output = 7;
    }

    function frDealsOfIA(address ia) external view returns (address) {
        return _frDeals[ia];
    }

    function mockResultsOfIA(address ia) external view returns (address) {
        return _mockResults[ia];
    }
}
