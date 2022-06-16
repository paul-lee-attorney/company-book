/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../../common/lib/ObjGroup.sol";

import "../../boa/interfaces/IInvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
// import "../../../common/lib/SafeMath.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/SNParser.sol";

import "../../../common/components/interfaces/ISigPage.sol";

contract AntiDilution is BOSSetting, BOMSetting, DraftControl {
    using SNFactory for bytes;
    using ArrayUtils for bytes32[];
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.UserGroup;

    // benchmark => _obligors
    mapping(bytes32 => ObjGroup.UserGroup) private _obligors;

    // class => bool
    mapping(uint8 => bool) public isMarked;

    // class => benchmark
    mapping(uint8 => bytes32) public classToMark;

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
        require(isMarked[class], "股价基准 不存在");
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

        isMarked[class] = true;
        classToMark[class] = sn;
        sn.insertToQue(_benchmarks);

        emit SetBenchmark(class, price);
    }

    function delBenchmark(uint8 class) external onlyAttorney onlyMarked(class) {
        bytes32 mark = classToMark[class];

        delete _obligors[mark];
        delete isMarked[class];
        delete classToMark[class];

        _benchmarks.removeByValue(mark);

        emit DelBenchmark(class);
    }

    function addObligor(uint8 class, uint40 acct)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[classToMark[class]].addMember(acct))
            emit AddObligor(class, acct);
    }

    function removeObligor(uint8 class, uint40 acct)
        external
        onlyAttorney
        onlyMarked(class)
    {
        if (_obligors[classToMark[class]].removeMember(acct))
            emit RemoveObligor(class, acct);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function obligors(uint8 class)
        external
        view
        onlyMarked(class)
        returns (uint40[])
    {
        return _obligors[classToMark[class]].members;
    }

    function benchmarks() external view returns (bytes32[] marks) {
        return marks = _benchmarks;
    }

    function giftPar(
        address ia,
        bytes32 snOfDeal,
        bytes32 shareNumber
    ) external view onlyMarked(shareNumber.class()) returns (uint256) {
        uint256 markPrice = classToMark[shareNumber.class()].priceOfMark();

        uint256 dealPrice = IInvestmentAgreement(ia).unitPrice(
            snOfDeal.sequenceOfDeal()
        );

        require(markPrice > dealPrice, "AntiDilution not triggered");

        (, uint256 parValue, , , , ) = _bos.getShare(shareNumber.short());

        return (parValue * markPrice) / dealPrice - parValue;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        public
        view
        onlyKeeper
        returns (bool)
    {
        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        if (sn.typeOfDeal() > 1) return false;
        if (unitPrice < _benchmarks[_benchmarks.length - 1].priceOfMark())
            return true;
        else return false;
    }

    function _isExempted(uint256 price, uint40[] consentParties)
        private
        view
        returns (bool)
    {
        require(consentParties.length > 0, "豁免方人数应大于“0”");

        uint8 i = uint8(_benchmarks.length);

        while (i > 0 && uint256(bytes31(_benchmarks[i - 1])) > price) {
            uint40[] memory classMember = _bosCal.membersOfClass(
                uint8(_benchmarks[i - 1][31])
            );

            if (classMember.length > consentParties.length) {
                return false;
            } else {
                bool flag;
                for (uint256 j = 0; j < classMember.length; j++) {
                    flag = false;
                    for (uint256 k = 0; k < consentParties.length; k++) {
                        if (consentParties[k] == classMember[j]) {
                            flag = true;
                            break;
                        }
                    }
                    if (!flag) return false;
                }
            }
            if (i > 0) i--;
        }

        return true;
    }

    function isExempted(address ia, bytes32 sn)
        public
        view
        onlyKeeper
        returns (bool)
    {
        if (!isTriggered(ia, sn)) return true;

        (uint40[] memory consentParties, ) = _bom.getYea(ia);

        uint256 unitPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );

        return _isExempted(unitPrice, consentParties);
    }
}
