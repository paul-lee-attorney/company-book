/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/ObjsRepo.sol";

import "./IAntiDilution.sol";
import "./ITerm.sol";

contract AntiDilution is
    IAntiDilution,
    ITerm,
    BOSSetting,
    BOMSetting,
    DraftControl
{
    // using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.MarkChain;
    using ArrayUtils for uint40[];
    // using ObjsRepo for ObjsRepo.SeqList;

    mapping(uint256 => EnumerableSet.UintSet) private _obligors;

    ObjsRepo.MarkChain private _benchmarks;

    // // benchmark => _obligors
    // mapping(bytes32 => EnumerableSet.UintSet) private _obligors;

    // ObjsRepo.SeqList private _benchmarks;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint8 class) {
        require(_benchmarks.contains(class), "no priced maked for the class");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setBenchmark(uint8 class, uint64 price) external onlyAttorney {
        if (_benchmarks.addMark(class, price)) emit SetBenchmark(class, price);
    }

    function delBenchmark(uint8 class) external onlyAttorney onlyMarked(class) {
        if (_benchmarks.removeMark(class)) emit DelBenchmark(class);
    }

    function addObligor(uint8 class, uint40 acct)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[class].add(acct)) emit AddObligor(class, acct);
    }

    function removeObligor(uint8 class, uint40 acct)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[class].remove(acct)) emit RemoveObligor(class, acct);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint8 class) external view onlyUser returns (bool) {
        return _benchmarks.contains(class);
    }

    function getBenchmark(uint8 class)
        external
        view
        onlyMarked(class)
        onlyUser
        returns (uint256)
    {
        return _benchmarks.markedValue(class);
    }

    function obligors(uint8 class)
        external
        view
        onlyMarked(class)
        onlyUser
        returns (uint40[])
    {
        return _obligors[class].valuesToUint40();
    }

    function giftPar(
        address ia,
        bytes32 snOfDeal,
        bytes32 shareNumber
    ) external view onlyMarked(shareNumber.class()) onlyUser returns (uint256) {
        uint256 markPrice = _benchmarks.markedValue(shareNumber.class());

        uint256 dealPrice = IInvestmentAgreement(ia).unitPrice(
            snOfDeal.sequence()
        );

        require(markPrice > dealPrice, "AntiDilution not triggered");

        (, , uint256 paidPar, , , ) = _bos.getShare(shareNumber.short());

        return (paidPar * markPrice) / dealPrice - paidPar;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        public
        view
        onlyUser
        returns (bool)
    {
        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
            return false;
        if (unitPrice < _benchmarks.topValue()) return true;
        else return false;
    }

    function _isExempted(uint256 price, uint40[] consentParties)
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

    function isExempted(address ia, bytes32 sn)
        public
        view
        onlyUser
        returns (bool)
    {
        if (!isTriggered(ia, sn)) return true;

        (uint40[] memory consentParties, ) = _bom.getYea(uint256(ia));

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());

        return _isExempted(unitPrice, consentParties);
    }
}
