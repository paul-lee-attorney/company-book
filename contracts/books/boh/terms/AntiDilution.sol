/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/IInvestmentAgreement.sol";

import "../../../common/ruting/IBookSetting.sol";
import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";
import "../../../common/access/AccessControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/ObjsRepo.sol";

import "./IAntiDilution.sol";
import "./ITerm.sol";

contract AntiDilution is IAntiDilution, ITerm, BOSSetting, BOMSetting {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.MarkChain;
    using ArrayUtils for uint40[];

    mapping(uint => EnumerableSet.UintSet) private _obligors;

    ObjsRepo.MarkChain private _benchmarks;

    // // benchmark => _obligors
    // mapping(bytes32 => EnumerableSet.UintSet) private _obligors;

    // ObjsRepo.SeqList private _benchmarks;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint16 class) {
        require(_benchmarks.contains(class), "no priced maked for the class");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setBenchmark(uint16 class, uint32 price) external onlyAttorney {
        if (_benchmarks.addMark(class, price)) emit SetBenchmark(class, price);
    }

    function delBenchmark(uint16 class) external onlyAttorney onlyMarked(class) {
        if (_benchmarks.removeMark(class)) emit DelBenchmark(class);
    }

    function addObligor(uint16 class, uint40 obligor)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[class].add(obligor)) emit AddObligor(class, obligor);
    }

    function removeObligor(uint16 class, uint40 obligor)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[class].remove(obligor))
            emit RemoveObligor(class, obligor);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint16 class) external view returns (bool) {
        return _benchmarks.contains(class);
    }

    function getBenchmark(uint16 class)
        external
        view
        onlyMarked(class)
        returns (uint64)
    {
        return _benchmarks.markedValue(class);
    }

    function obligors(uint16 class)
        external
        view
        onlyMarked(class)
        returns (uint40[])
    {
        return _obligors[class].valuesToUint40();
    }

    function giftPar(
        address ia,
        bytes32 snOfDeal,
        bytes32 shareNumber
    ) external view onlyMarked(shareNumber.class()) returns (uint64) {
        uint64 markPrice = _benchmarks.markedValue(shareNumber.class());

        uint64 dealPrice = IInvestmentAgreement(ia).unitPrice(
            snOfDeal.sequence()
        );

        require(markPrice > dealPrice, "AntiDilution not triggered");

        (, , uint64 paidPar, , , ) = _bos.getShare(shareNumber.ssn());

        return (paidPar * markPrice) / dealPrice - paidPar;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool) {
        uint64 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        if (
            sn.typeOfDeal() != uint8(EnumsRepo.TypeOfDeal.CapitalIncrease) &&
            sn.typeOfDeal() != uint8(EnumsRepo.TypeOfDeal.PreEmptive)
        ) return false;
        if (unitPrice < _benchmarks.topValue()) return true;
        else return false;
    }

    function _isExempted(uint32 price, uint40[] consentParties)
        private
        view
        returns (bool)
    {
        require(consentParties.length > 0, "zero consentParties");

        uint8 cur = uint8(_benchmarks.topKey());

        while (cur > 0) {
            if (_benchmarks.markedValue(cur) <= price) break;

            uint40[] memory classMember = _bosCal.membersOfClass(cur);

            if (classMember.length > consentParties.length) return false;
            else if (!classMember.fullyCoveredBy(consentParties)) return false;

            cur = uint8(_benchmarks.prevKey(cur));
        }

        return true;
    }

    function isExempted(address ia, bytes32 sn) public view returns (bool) {
        if (!isTriggered(ia, sn)) return true;

        (uint40[] memory consentParties, ) = _bom.getYea(uint256(ia));

        uint32 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        return _isExempted(unitPrice, consentParties);
    }
}
