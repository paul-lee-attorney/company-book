/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// import "../../../common/lib/EnumerableSet.sol";

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, BOSSetting, BOMSetting, DraftControl {
    using SNFactory for bytes;
    using ArrayUtils for bytes32[];
    using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // benchmark => _obligors
    mapping(bytes32 => EnumerableSet.UintSet) private _obligors;

    // class => bool
    mapping(uint8 => bool) private _isMarked;

    // class => benchmark
    mapping(uint8 => bytes32) private _classToMark;

    bytes32[] private _benchmarks;

    // ################
    // ##   Event    ##
    // ################

    event SetBenchmark(uint8 indexed class, uint256 price);

    event DelBenchmark(uint8 indexed class);

    event AddObligor(uint256 indexed class, uint40 obligor);

    event RemoveObligor(uint256 indexed class, uint40 obligor);

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint8 class) {
        require(_isMarked[class], "no priced maked for the class");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createSN(uint8 class, uint256 price)
        private
        pure
        returns (bytes32 sn)
    {
        bytes memory _sn = new bytes(32);
        _sn = _sn.intToSN(0, price, 31);
        _sn[31] = bytes1(class);

        sn = _sn.bytesToBytes32();
    }

    function setBenchmark(uint8 class, uint256 price) external onlyAttorney {
        bytes32 sn = _createSN(class, price);

        _isMarked[class] = true;
        _classToMark[class] = sn;
        sn.insertToQue(_benchmarks);

        emit SetBenchmark(class, price);
    }

    function delBenchmark(uint8 class) external onlyAttorney onlyMarked(class) {
        bytes32 mark = _classToMark[class];

        delete _obligors[mark];
        delete _isMarked[class];
        delete _classToMark[class];

        _benchmarks.removeByValue(mark);

        emit DelBenchmark(class);
    }

    function addObligor(uint8 class, uint40 acct)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[_classToMark[class]].add(uint256(acct)))
            emit AddObligor(class, acct);
    }

    function removeObligor(uint8 class, uint40 acct)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[_classToMark[class]].remove(uint256(acct)))
            emit RemoveObligor(class, acct);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint8 class) external view onlyUser returns (bool) {
        return _isMarked[class];
    }

    function classToMark(uint8 class) external view onlyUser returns (bytes32) {
        return _classToMark[class];
    }

    function obligors(uint8 class)
        external
        view
        onlyMarked(class)
        onlyUser
        returns (uint40[])
    {
        return _obligors[_classToMark[class]].valuesToUint40();
    }

    function benchmarks() external view onlyUser returns (bytes32[] marks) {
        return marks = _benchmarks;
    }

    function giftPar(
        address ia,
        bytes32 snOfDeal,
        bytes32 shareNumber
    ) external view onlyMarked(shareNumber.class()) onlyUser returns (uint256) {
        uint256 markPrice = _classToMark[shareNumber.class()].priceOfMark();

        uint256 dealPrice = IInvestmentAgreement(ia).unitPrice(
            snOfDeal.sequenceOfDeal()
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
        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        if (sn.typeOfDeal() > uint8(EnumsRepo.TypeOfDeal.PreEmptive))
            return false;
        if (unitPrice < _benchmarks[_benchmarks.length - 1].priceOfMark())
            return true;
        else return false;
    }

    function _isExempted(uint256 price, uint40[] consentParties)
        private
        view
        returns (bool)
    {
        require(consentParties.length > 0, "zero consentParties");

        uint256 len = _benchmarks.length;

        while (len > 0) {
            if (_benchmarks[len - 1].priceOfMark() <= price) break;

            uint40[] memory classMember = _bosCal.membersOfClass(
                _benchmarks[len - 1].classOfMark()
            );

            if (classMember.length > consentParties.length) return false;
            else if (!classMember.fullyCoveredBy(consentParties)) return false;

            len--;
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

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        return _isExempted(unitPrice, consentParties);
    }
}
