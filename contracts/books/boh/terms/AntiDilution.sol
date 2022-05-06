/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../../common/config/BOSSetting.sol";
import "../../../common/config/BOMSetting.sol";
import "../../../common/config/DraftSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SafeMath.sol";
import "../../../common/lib/serialNumber/SNFactory.sol";
import "../../../common/lib/serialNumber/DealSNParser.sol";

import "../../../common/interfaces/IAgreement.sol";
import "../../../common/interfaces/ISigPage.sol";

contract AntiDilution is BOSSetting, BOMSetting, DraftSetting {
    using SNFactory for bytes;
    using ArrayUtils for address[];
    using ArrayUtils for bytes32[];
    using DealSNParser for bytes32;

    // benchmark => obligors
    mapping(bytes32 => address[]) public obligors;

    // class => bool
    mapping(uint8 => bool) public isMarked;

    // class => benchmark
    mapping(uint8 => bytes32) public classToMark;

    bytes32[] public benchmarks;

    // ################
    // ##   Event    ##
    // ################

    event SetBenchmark(uint8 indexed class, uint256 price);

    event DelBenchmark(uint8 indexed class);

    event AddObligor(uint256 indexed class, address obligor);

    event RemoveObligor(uint256 indexed class, address obligor);

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

        uint256 len = benchmarks.length;
        benchmarks.push(sn);

        for (uint256 i = 0; i < len; i++) {
            if (benchmarks[len - 1 - i] > benchmarks[len - i])
                (benchmarks[len - 1 - i], benchmarks[len - i]) = (
                    benchmarks[len - i],
                    benchmarks[len - 1 - i]
                );
            else break;
        }

        emit SetBenchmark(class, price);
    }

    function delBenchmark(uint8 class) external onlyAttorney onlyMarked(class) {
        bytes32 mark = classToMark[class];

        delete obligors[mark];
        delete isMarked[class];
        delete classToMark[class];

        benchmarks.removeByValue(mark);

        emit DelBenchmark(class);
    }

    function addObligor(uint8 class, address obligor)
        external
        onlyAttorney
        onlyMarked(class)
    {
        ISigPage(getGK()).isParty(obligor);

        (bool exist, ) = obligors[classToMark[class]].firstIndexOf(obligor);

        if (!exist) {
            obligors[classToMark[class]].push(obligor);
            emit AddObligor(class, obligor);
        }
    }

    function removeObligor(uint8 class, address obligor)
        external
        onlyAttorney
        onlyMarked(class)
    {
        (bool exist, ) = obligors[classToMark[class]].firstIndexOf(obligor);

        if (exist) {
            obligors[classToMark[class]].removeByValue(obligor);
            emit RemoveObligor(class, obligor);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getBenchmarks()
        external
        view
        onlyStakeholders
        returns (bytes32[] marks)
    {
        return marks = benchmarks;
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
        (, uint256 unitPrice, , , , , ) = IAgreement(ia).getDeal(
            sn.sequenceOfDeal()
        );
        uint8 typeOfDeal = uint8(sn[3]);

        if (typeOfDeal > 1) return false;
        if (unitPrice < uint256(bytes31(benchmarks[benchmarks.length - 1])))
            return true;
        else return false;
    }

    function _isExempted(uint256 price, address[] consentParties)
        private
        view
        returns (bool)
    {
        require(consentParties.length > 0, "豁免方人数应大于“0”");

        uint8 i = uint8(benchmarks.length);

        while (i > 0 && uint256(bytes31(benchmarks[i - 1])) > price) {
            address[] memory classMember = _bosCal.membersOfClass(
                uint8(benchmarks[i - 1][31])
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

        (address[] memory consentParties, ) = _bom.getYea(ia);

        (, uint256 unitPrice, , , , , ) = IAgreement(ia).getDeal(
            sn.sequenceOfDeal()
        );

        return _isExempted(unitPrice, consentParties);
    }
}
