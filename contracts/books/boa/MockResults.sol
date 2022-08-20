/* *
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./IMockResults.sol";

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SNParser.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/IASetting.sol";

contract MockResults is IMockResults, IASetting, SHASetting, BOSSetting {
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for bytes32;

    struct Amt {
        uint64 selAmt;
        uint64 buyAmt;
        uint64 orgAmt;
        uint64 rstAmt;
    }

    // groupNo => Amt
    mapping(uint16 => Amt) private _mockResults;

    EnumerableSet.UintSet private _groupsConcerned;

    // // ssnOfDeal => bool
    // mapping(uint16 => bool) private _isMocked;

    struct TopGroup {
        uint16 groupNum;
        uint64 amount;
        bool isOrgController;
        uint16 shareRatio;
        Amt sumOfIA;
    }

    TopGroup private _topGroup;

    //#################
    //##  Write I/O  ##
    //#################

    function mockDealsOfIA() external onlyManager(0) returns (bool) {
        bytes32[] memory dealsList = _ia.dealsList();
        uint256 len = dealsList.length;

        while (len > 0) {
            bytes32 sn = dealsList[len - 1];
            uint64 amount;

            if (_getSHA().basedOnPar())
                (, amount, , , ) = _ia.getDeal(sn.sequence());
            else (, , amount, , ) = _ia.getDeal(sn.sequence());

            uint32 short = sn.ssnOfDeal();
            if (short > 0) _mockDealOfSell(short, amount);

            _mockDealOfBuy(sn, amount);

            len--;
        }

        _calculateMockResult();

        return true;
    }

    function _mockDealOfSell(uint32 ssn, uint64 amount) private {
        (bytes32 shareNumber, , , , , ) = _bos.getShare(ssn);
        uint16 sellerGroup = _bos.groupNo(shareNumber.shareholder());

        _mockResults[sellerGroup].selAmt += amount;
        _groupsConcerned.add(sellerGroup);

        emit MockDealOfSell(sellerGroup, amount);
    }

    function _mockDealOfBuy(bytes32 sn, uint64 amount) private {
        uint16 buyerGroup = _bos.groupNo(sn.buyerOfDeal());

        _mockResults[buyerGroup].buyAmt += amount;
        _groupsConcerned.add(buyerGroup);

        emit MockDealOfBuy(buyerGroup, amount);
    }

    function _calculateMockResult() private {
        uint16[] memory groups = _groupsConcerned.valuesToUint16();

        uint256 len = groups.length;
        bool basedOnPar = _getSHA().basedOnPar();

        while (len > 0) {
            uint16 groupNum = groups[len - 1];

            Amt storage group = _mockResults[groupNum];

            group.orgAmt = basedOnPar
                ? _bosCal.parOfGroup(groupNum)
                : _bosCal.paidOfGroup(groupNum);

            require(
                group.orgAmt + group.buyAmt >= group.selAmt,
                "amount OVER FLOW"
            );
            group.rstAmt = group.orgAmt + group.buyAmt - group.selAmt;

            if (group.rstAmt > _topGroup.amount) {
                _topGroup.amount = group.rstAmt;
                _topGroup.groupNum = groupNum;
            }

            _topGroup.sumOfIA.buyAmt += group.buyAmt;
            _topGroup.sumOfIA.selAmt += group.selAmt;
        }

        require(
            _topGroup.sumOfIA.buyAmt >= _topGroup.sumOfIA.selAmt,
            "sell amount over flow"
        );

        _topGroup.sumOfIA.rstAmt =
            _topGroup.sumOfIA.buyAmt -
            _topGroup.sumOfIA.selAmt;

        _checkController(basedOnPar);

        emit CalculateResult(
            _topGroup.groupNum,
            _topGroup.amount,
            _topGroup.isOrgController,
            _topGroup.shareRatio
        );
    }

    function _checkController(bool basedOnPar) private {
        uint16 controller = _bos.controller();
        uint64 amtOfCorp = basedOnPar ? _bos.regCap() : _bos.paidCap();
        amtOfCorp += _topGroup.sumOfIA.rstAmt;

        if (_groupsConcerned.contains(controller)) {
            if (_topGroup.groupNum == controller)
                _topGroup.isOrgController = true;
        } else {
            uint64 amtOfController = basedOnPar
                ? _bosCal.parOfGroup(controller)
                : _bosCal.paidOfGroup(controller);

            if (_topGroup.amount < amtOfController) {
                _topGroup.isOrgController = true;
                _topGroup.groupNum = controller;
                _topGroup.amount = amtOfController;
            }
        }
        _topGroup.shareRatio = uint16((_topGroup.amount * 10000) / amtOfCorp);
    }

    function addAlongDeal(
        bytes32 rule,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar
    ) external onlyManager(0) {
        uint16 drager = rule.dragerOfLink();
        uint16 follower = _bos.groupNo(shareNumber.shareholder());

        Amt storage fAmt = _mockResults[follower];

        if (_groupsConcerned.add(follower))
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
            Amt storage dAmt = _mockResults[drager];

            require(
                dAmt.selAmt >=
                    (fAmt.selAmt * dAmt.orgAmt) / fAmt.orgAmt + dAmt.buyAmt,
                "sell amount over flow"
            );
        }

        fAmt.rstAmt = fAmt.orgAmt - fAmt.selAmt;

        emit AddAlongDeal(follower, shareNumber, parValue, paidPar);
    }

    function acceptAlongDeal(bytes32 sn) external onlyKeeper {
        uint16 buyerGroup = _bos.groupNo(sn.buyerOfDeal());

        (, uint64 parValue, uint64 paidPar, , ) = _ia.getDeal(sn.sequence());

        Amt storage bAmt = _mockResults[buyerGroup];

        if (_getSHA().basedOnPar()) bAmt.buyAmt += parValue;
        else bAmt.buyAmt += paidPar;

        bAmt.rstAmt = bAmt.orgAmt + bAmt.buyAmt - bAmt.selAmt;

        // _isMocked[sn.sequence()] = true;

        emit AcceptAlongDeal(sn);
    }

    //##################
    //##    读接口    ##
    //##################

    function groupsConcerned() external view returns (uint16[]) {
        return _groupsConcerned.valuesToUint16();
    }

    function isConcernedGroup(uint16 group) external view returns (bool) {
        return _groupsConcerned.contains(group);
    }

    function topGroup()
        external
        view
        returns (
            uint16 groupNum,
            uint64 amount,
            bool isOrgController,
            uint16 shareRatio,
            uint64 netIncreasedAmt
        )
    {
        groupNum = _topGroup.groupNum;
        amount = _topGroup.amount;
        isOrgController = _topGroup.isOrgController;
        shareRatio = _topGroup.shareRatio;
        netIncreasedAmt = _topGroup.sumOfIA.rstAmt;
    }

    function mockResults(uint16 group)
        external
        view
        returns (
            uint64 selAmt,
            uint64 buyAmt,
            uint64 orgAmt,
            uint64 rstAmt
        )
    {
        require(_groupsConcerned.contains(group), "NOT a concerned group");

        Amt storage amt = _mockResults[group];
        selAmt = amt.selAmt;
        buyAmt = amt.buyAmt;
        orgAmt = amt.orgAmt;
        rstAmt = amt.rstAmt;
    }
}
