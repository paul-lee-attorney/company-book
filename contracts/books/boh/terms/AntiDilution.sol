// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";
import "../../boa/InvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/ROMSetting.sol";
import "../../../common/ruting/BOMSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/ArrowChain.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, BOSSetting, ROMSetting, BOMSetting {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ArrowChain for ArrowChain.MarkChain;
    using ArrayUtils for uint40[];

    mapping(uint256 => EnumerableSet.UintSet) private _obligors;

    ArrowChain.MarkChain private _benchmarks;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint16 class) {
        require(
            _benchmarks.contains(class),
            "AD.onlyMarked: no uint price maked for the class"
        );
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setBenchmark(uint16 class, uint32 price) external onlyAttorney {
        if (_benchmarks.addMark(class, price)) emit SetBenchmark(class, price);
    }

    function delBenchmark(uint16 class)
        external
        onlyAttorney
        onlyMarked(class)
    {
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
        returns (uint40[] memory)
    {
        return _obligors[class].valuesToUint40();
    }

    function giftPar(bytes32 snOfDeal, bytes32 shareNumber)
        external
        view
        onlyMarked(shareNumber.class())
        returns (uint64 gift)
    {
        uint64 markPrice = _benchmarks.markedValue(shareNumber.class());

        uint64 dealPrice = snOfDeal.priceOfDeal();

        require(markPrice > dealPrice, "AntiDilution not triggered");

        (, uint64 paid, , , ) = _bos.getShare(shareNumber.ssn());

        gift = (paid * markPrice) / dealPrice - paid;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool) {
        uint32 unitPrice = sn.priceOfDeal();

        if (
            sn.typeOfDeal() !=
            uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease) &&
            sn.typeOfDeal() != uint8(InvestmentAgreement.TypeOfDeal.PreEmptive)
        ) return false;

        if (unitPrice < _benchmarks.topValue()) return true;

        return false;
    }

    function _isExempted(uint32 price, uint40[] memory consentParties)
        private
        view
        returns (bool)
    {
        require(
            consentParties.length != 0,
            "AD.isExempted: zero consentParties"
        );

        uint16 cur = uint16(_benchmarks.topKey());

        while (cur != 0) {
            if (_benchmarks.markedValue(cur) <= price) break;

            uint40[] memory classMember = _membersOfClass(cur);

            if (classMember.length > consentParties.length) return false;
            else if (!classMember.fullyCoveredBy(consentParties)) return false;

            cur = uint8(_benchmarks.prevKey(cur));
        }

        return true;
    }

    function _membersOfClass(uint16 class)
        private
        view
        returns (uint40[] memory)
    {
        require(class < _bos.counterOfClasses(), "class over flow");

        bytes32[] memory list = _rom.sharesList();

        uint256 len = _rom.qtyOfMembers();
        uint40[] memory members = new uint40[](len);

        uint256 numOfMembers;
        len = list.length;

        while (len != 0) {
            if (list[len - 1].class() == class) {
                uint256 lenOfM = numOfMembers;
                while (lenOfM != 0) {
                    if (members[lenOfM - 1] == list[len - 1].shareholder())
                        break;
                    lenOfM--;
                }
                if (lenOfM == 0) {
                    numOfMembers++;
                    members[numOfMembers - 1] = list[len - 1].shareholder();
                }
            }
            len--;
        }

        uint40[] memory output = new uint40[](numOfMembers);

        assembly {
            output := members
        }

        return output;
    }

    function isExempted(address ia, bytes32 sn) external view returns (bool) {
        if (!isTriggered(ia, sn)) return true;

        (uint40[] memory consentParties, ) = _bom.getYea(uint256(uint160(ia)));

        uint32 unitPrice = sn.priceOfDeal();

        return _isExempted(unitPrice, consentParties);
    }
}
