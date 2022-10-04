/* *
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./IInvestmentAgreement.sol";
import "./IBookOfIA.sol";

import "../../common/components/DocumentsRepo.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

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
            IAccessControl(frd).setManager(1, this, msg.sender);
        }
    }

    function createMockResults(address ia)
        external
        onlyKeeper
        returns (address mock)
    {
        address creator = msg.sender;

        if (_mockResults[ia] == address(0)) {
            mock = createDoc(2, _rc.userNo(creator));
            IAccessControl(mock).init(
                creator,
                this,
                _rc,
                uint8(EnumsRepo.RoleOfUser.MockResults),
                _rc.entityNo(this)
            );
            IBookSetting(mock).setIA(ia);
            IBookSetting(mock).setBOS(_bos);
            IBookSetting(mock).setBOSCal(_bosCal);

            IAccessControl(mock).setManager(1, this, creator);
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
