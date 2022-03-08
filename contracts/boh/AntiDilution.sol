/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";
import "../config/BOMSetting.sol";
import "../config/DraftSetting.sol";

import "../lib/ArrayUtils.sol";
import "../lib/SafeMath.sol";

import "../interfaces/IAgreement.sol";
import "../interfaces/ISigPage.sol";

contract AntiDilution is BOSSetting, BOMSetting, DraftSetting {
    using ArrayUtils for address[];
    using SafeMath for uint8;

    struct Benchmark {
        uint8 rank;
        uint256 price;
        address[] obligors;
    }

    // class => Benchmark
    mapping(uint8 => Benchmark) private _benchmarks;

    // class => bool
    mapping(uint8 => bool) public classIsMarked;

    // rank => class
    mapping(uint8 => uint8) private _classRanked;

    uint8 public qtyOfMarks;

    // ################
    // ##   Event    ##
    // ################

    event SetBenchmark(uint8 indexed class, uint256 price, uint8 indexed rank);

    event DelBenchmark(uint8 indexed class);

    event AddObligor(uint256 indexed class, address obligor);

    event RemoveObligor(uint256 indexed class, address obligor);

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint8 class) {
        require(classIsMarked[class], "股价基准 不存在");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _insertPrice(uint8 class, uint256 price) private returns (uint8) {
        require(price > 0, "标定 价格 应大于0");

        classIsMarked[class] = true;
        _benchmarks[class].price = price;
        qtyOfMarks = qtyOfMarks.add8(1);

        _classRanked[qtyOfMarks - 1] = class;
        _benchmarks[class].rank = qtyOfMarks - 1;

        for (uint8 i = qtyOfMarks - 1; i > 0; i--) {
            if (
                _benchmarks[_classRanked[i - 1]].price >
                _benchmarks[_classRanked[i]].price
            ) {
                uint256 t = _benchmarks[_classRanked[i]].price;
                _benchmarks[_classRanked[i]].price = _benchmarks[
                    _classRanked[i - 1]
                ].price;
                _benchmarks[_classRanked[i - 1]].price = t;

                _benchmarks[_classRanked[i]].rank = i - 1;
                _benchmarks[_classRanked[i - 1]].rank = i;

                uint8 k = _classRanked[i];
                _classRanked[i] = _classRanked[i - 1];
                _classRanked[i - 1] = k;
            } else {
                return i;
            }
        }
        return 0;
    }

    function _removePrice(uint8 class) private {
        uint8 rank = _benchmarks[class].rank;

        while (rank < qtyOfMarks - 1) {
            _benchmarks[_classRanked[rank + 1]].rank = rank;
            _classRanked[rank] = _classRanked[rank + 1];
            rank++;
        }

        delete _benchmarks[class];
        delete _classRanked[qtyOfMarks - 1];
        qtyOfMarks--;
    }

    function setBenchmark(uint8 class, uint256 price) external onlyAttorney {
        if (classIsMarked[class]) _removePrice(class);

        uint8 rank = _insertPrice(class, price);

        emit SetBenchmark(class, price, rank);
    }

    function delBenchmark(uint8 class) external onlyAttorney onlyMarked(class) {
        _removePrice(class);

        emit DelBenchmark(class);
    }

    function addObligor(uint8 class, address obligor)
        external
        onlyAttorney
        onlyMarked(class)
    {
        // require(_getBOS().isMember(obligor) || _isInvestor(obligor), "反稀释 义务人 应为股东或投资人");

        ISigPage(getBookeeper()).isParty(obligor);

        (bool exist, ) = _benchmarks[class].obligors.firstIndexOf(obligor);

        if (!exist) {
            _benchmarks[class].obligors.push(obligor);
            emit AddObligor(class, obligor);
        }
    }

    function removeObligor(uint8 class, address obligor)
        external
        onlyAttorney
        onlyMarked(class)
    {
        (bool exist, ) = _benchmarks[class].obligors.firstIndexOf(obligor);

        if (exist) {
            _benchmarks[class].obligors.removeByValue(obligor);
            emit RemoveObligor(class, obligor);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getBenchmark(uint8 class)
        external
        view
        onlyStakeholders
        onlyMarked(class)
        returns (
            uint8 rank,
            uint256 price,
            address[] obligors
        )
    {
        rank = _benchmarks[class].rank;
        price = _benchmarks[class].price;
        obligors = _benchmarks[class].obligors;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, uint8 snOfDeal)
        public
        view
        onlyBookeeper
        returns (bool)
    {
        (, , , , uint256 unitPrice, , , , uint8 typeOfDeal, , ) = IAgreement(ia)
            .getDeal(snOfDeal);

        if (typeOfDeal > 1) return false;
        if (unitPrice < _benchmarks[_classRanked[qtyOfMarks - 1]].price)
            return true;
        else return false;
    }

    function _isExempted(uint256 price, address[] consentParties)
        private
        view
        returns (bool)
    {
        require(consentParties.length > 0, "豁免方人数应大于“0”");

        uint8 i = qtyOfMarks;

        while (i > 0 && _benchmarks[_classRanked[i - 1]].price > price) {
            address[] memory classMember = _bos.membersOfClass(
                _classRanked[i - 1]
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

    function isExempted(address ia, uint8 snOfDeal)
        public
        view
        onlyBookeeper
        returns (bool)
    {
        if (!isTriggered(ia, snOfDeal)) return true;

        (address[] memory consentParties, ) = _bom.getYea(ia);

        (, , , , uint256 unitPrice, , , , , , ) = IAgreement(ia).getDeal(
            snOfDeal
        );

        return _isExempted(unitPrice, consentParties);
    }
}
