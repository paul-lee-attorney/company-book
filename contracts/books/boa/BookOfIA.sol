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

contract BookOfIA is IBookOfIA, DocumentsRepo {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Amt {
        uint64 selAmt;
        uint64 buyAmt;
        uint64 orgAmt;
        uint64 rstAmt;
    }

    // IA address => group => Amt
    mapping(address => mapping(uint16 => Amt)) private _mockResults;

    // IA address => UintSet
    mapping(address => EnumerableSet.UintSet) private _groupsConcerned;

    // IA address => deal seq => bool
    mapping(address => mapping(uint16 => bool)) private _isMocked;

    struct TopGroup {
        uint16 groupNum;
        uint64 amount;
        bool isOrgController;
        uint16 shareRatio;
        Amt sumOfIA;
    }

    // IA address => topGroup
    mapping(address => TopGroup) private _topGroups;

    //#################
    //##  Write I/O  ##
    //#################

    function circulateIA(address ia, uint40 submitter) external onlyManager(1) {
        bytes32 rule = _getSHA().votingRules(typeOfIA(ia));

        circulateDoc(ia, rule, submitter);
    }

    function mockDealOfSell(
        address ia,
        uint40 seller,
        uint64 amount
    ) external onlyManager(1) {
        uint16 sellerGroup = _bos.groupNo(seller);
        _mockResults[ia][sellerGroup].selAmt += amount;
        _groupsConcerned[ia].add(sellerGroup);
    }

    function mockDealOfBuy(
        address ia,
        uint16 ssn,
        uint40 buyer,
        uint64 amount
    ) external onlyManager(1) {
        uint16 buyerGroup = _bos.groupNo(buyer);

        if (!_isMocked[ia][ssn]) {
            _mockResults[ia][buyerGroup].buyAmt += amount;
            _groupsConcerned[ia].add(buyerGroup);

            _isMocked[ia][ssn] = true;
        }
    }

    function calculateMockResult(address ia) external onlyManager(1) {
        uint16[] memory groups = _groupsConcerned[ia].valuesToUint16();

        delete _topGroups[ia];
        TopGroup storage top = _topGroups[ia];

        uint256 len = groups.length;
        bool basedOnPar = _getSHA().basedOnPar();

        while (len > 0) {
            uint16 groupNum = uint16(groups[len - 1]);

            Amt storage group = _mockResults[ia][groupNum];

            if (_bos.isGroup(groupNum))
                group.orgAmt = basedOnPar
                    ? _bosCal.parOfGroup(groupNum)
                    : _bosCal.paidOfGroup(groupNum);

            require(
                group.orgAmt + group.buyAmt >= group.selAmt,
                "amount OVER FLOW"
            );
            group.rstAmt = group.orgAmt + group.buyAmt - group.selAmt;

            if (group.rstAmt > top.amount) {
                top.amount = group.rstAmt;
                top.groupNum = groupNum;
            }

            top.sumOfIA.buyAmt += group.buyAmt;
            top.sumOfIA.selAmt += group.selAmt;
        }

        require(
            top.sumOfIA.buyAmt >= top.sumOfIA.selAmt,
            "sell amount over flow"
        );

        top.sumOfIA.rstAmt = top.sumOfIA.buyAmt - top.sumOfIA.selAmt;

        _checkController(ia, basedOnPar);

        emit CalculateResult(
            ia,
            top.groupNum,
            top.amount,
            top.isOrgController,
            top.shareRatio
        );
    }

    function _checkController(address ia, bool basedOnPar) private {
        TopGroup storage top = _topGroups[ia];

        uint16 controller = _bos.controller();
        uint64 amtOfCorp = basedOnPar ? _bos.regCap() : _bos.paidCap();
        amtOfCorp += top.sumOfIA.rstAmt;

        if (_groupsConcerned[ia].contains(controller)) {
            if (top.groupNum == controller) top.isOrgController = true;
        } else {
            uint64 amtOfController = basedOnPar
                ? _bosCal.parOfGroup(controller)
                : _bosCal.paidOfGroup(controller);

            if (top.amount < amtOfController) {
                top.isOrgController = true;
                top.groupNum = controller;
                top.amount = amtOfController;
            }
        }
        top.shareRatio = uint16((top.amount * 10000) / amtOfCorp);
    }

    // ======== Propose IA ========

    // function proposeIA(
    //     address ia,
    //     uint32 proposeDate,
    //     uint40 caller
    // )
    //     public
    //     onlyManager(1)
    //     onlyRegistered(ia)
    //     currentDate(proposeDate)
    //     onlyForCirculated(ia)
    // {
    //     Doc storage doc = _docs[ia];

    //     require(doc.reviewDeadlineBN <= block.number, "still in review period");

    //     pushToNextState(ia, caller);
    // }

    function addAlongDeal(
        address ia,
        bytes32 rule,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external onlyManager(1) {
        uint16 drager = rule.dragerOfLink();
        uint16 follower = _bos.groupNo(shareNumber.shareholder());

        Amt storage fAmt = _mockResults[ia][follower];

        if (_groupsConcerned[ia].add(follower))
            fAmt.orgAmt = _getSHA().basedOnPar()
                ? _bosCal.parOfGroup(follower)
                : _bosCal.paidOfGroup(follower);

        if (_getSHA().basedOnPar()) {
            require(
                fAmt.orgAmt >= (fAmt.selAmt + parValue),
                "parValue over flow"
            );
            fAmt.selAmt += parValue;
        } else {
            require(
                fAmt.orgAmt >= (fAmt.selAmt + paidPar),
                "paidPar over flow"
            );
            fAmt.selAmt += paidPar;
        }

        if (rule.proRataOfLink()) {
            Amt storage dAmt = _mockResults[ia][drager];

            require(
                dAmt.selAmt >=
                    (fAmt.selAmt * dAmt.orgAmt) / fAmt.orgAmt + dAmt.buyAmt,
                "sell amount over flow"
            );
        }

        fAmt.rstAmt = fAmt.orgAmt - fAmt.selAmt;

        emit AddAlongDeal(ia, follower, shareNumber, parValue, paidPar);
    }

    function acceptAlongDeal(address ia, bytes32 sn) external onlyKeeper {
        uint16 buyerGroup = _bos.groupNo(sn.buyerOfDeal());

        (, uint64 parValue, uint64 paidPar, , ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequence());

        Amt storage bAmt = _mockResults[ia][buyerGroup];

        if (_getSHA().basedOnPar()) bAmt.buyAmt += parValue;
        else bAmt.buyAmt += paidPar;

        bAmt.rstAmt = bAmt.orgAmt + bAmt.buyAmt - bAmt.selAmt;

        _isMocked[ia][sn.sequence()] = true;

        emit AcceptAlongDeal(ia, sn);
    }

    //##################
    //##    读接口    ##
    //##################

    function groupsConcerned(address ia) external view returns (uint16[]) {
        return _groupsConcerned[ia].valuesToUint16();
    }

    function isConcernedGroup(address ia, uint16 group)
        external
        view
        returns (bool)
    {
        return _groupsConcerned[ia].contains(group);
    }

    function topGroup(address ia)
        external
        view
        onlyRegistered(ia)
        onlyForCirculated(ia)
        returns (
            uint16 groupNum,
            uint64 amount,
            bool isOrgController,
            uint64 netIncreasedAmt,
            uint16 shareRatio
        )
    {
        TopGroup storage top = _topGroups[ia];

        groupNum = top.groupNum;
        amount = top.amount;
        isOrgController = top.isOrgController;
        netIncreasedAmt = top.sumOfIA.rstAmt;
        shareRatio = top.shareRatio;
    }

    function mockResults(address ia, uint16 group)
        external
        view
        onlyForCirculated(ia)
        returns (
            uint64 selAmt,
            uint64 buyAmt,
            uint64 orgAmt,
            uint64 rstAmt
        )
    {
        require(_groupsConcerned[ia].contains(group), "NOT concerned group");

        Amt storage amt = _mockResults[ia][group];
        selAmt = amt.selAmt;
        buyAmt = amt.buyAmt;
        orgAmt = amt.orgAmt;
        rstAmt = amt.rstAmt;
    }

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
}
