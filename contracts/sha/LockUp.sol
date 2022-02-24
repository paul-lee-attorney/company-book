/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";
import "../config/BOMSetting.sol";
import "../config/DraftSetting.sol";

import "../lib/ArrayUtils.sol";

import "../interfaces/IAgreement.sol";
import "../interfaces/ISigPage.sol";

// import "../interfaces/IMotion.sol";

contract LockUp is BOSSetting, BOMSetting, DraftSetting {
    using ArrayUtils for uint256[];
    using ArrayUtils for address[];

    // 股票锁定柜
    struct Locker {
        uint256 dueDate;
        address[] keyHolders;
    }

    // 基准日条件未成就时，按“2277-09-19”设定到期日
    uint256 constant REMOTE_FUTURE = 9710553600;

    // shareNumber => Locker
    mapping(uint256 => Locker) private _lockers;

    // shareNumber => bool
    mapping(uint256 => bool) private _isLocked;

    // ################
    // ##   Event   ##
    // ################

    event SetLocker(uint256 indexed shareNumber, uint256 dueDate);

    event AddKeyholder(uint256 indexed shareNumber, address keyholder);

    event RemoveKeyholder(uint256 indexed shareNumber, address keyholder);

    event DelLocker(uint256 indexed shareNumber);

    // ################
    // ##  Modifier  ##
    // ################

    modifier beLocked(uint256 shareNumber) {
        require(_isLocked[shareNumber], "股权未被锁定");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(uint256 shareNumber, uint256 dueDate)
        external
        onlyAttorney
        beShare(shareNumber)
    {
        _lockers[shareNumber].dueDate = dueDate == 0 ? REMOTE_FUTURE : dueDate;
        _isLocked[shareNumber] = true;

        emit SetLocker(shareNumber, _lockers[shareNumber].dueDate);
    }

    function delLocker(uint256 shareNumber)
        external
        onlyAttorney
        beLocked(shareNumber)
    {
        delete _lockers[shareNumber];
        _isLocked[shareNumber] = false;

        emit DelLocker(shareNumber);
    }

    function addKeyholder(uint256 shareNumber, address keyholder)
        external
        onlyAttorney
        beLocked(shareNumber)
    // isMemberOrInvestor(keyholder)
    {
        // require(_getBOS().isMember(keyholder) || _isInvestor(keyholder), "权利人 应为股东或者投资人");
        ISigPage(getBookeeper()).isParty(keyholder);

        _lockers[shareNumber].keyHolders.addValue(keyholder);

        emit AddKeyholder(shareNumber, keyholder);
    }

    function removeKeyholder(uint256 shareNumber, address keyholder)
        external
        onlyAttorney
        beLocked(shareNumber)
    {
        // require(_isLocked[shareNumber], "股权未被锁定");

        _lockers[shareNumber].keyHolders.removeByValue(keyholder);

        emit RemoveKeyholder(shareNumber, keyholder);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function lockerExist(uint256 shareNumber)
        public
        view
        onlyStakeholders
        beShare(shareNumber)
        returns (bool)
    {
        // require(_getBOS().shareExist(shareNumber), "股权编号 错误");
        return _isLocked[shareNumber];
    }

    function getLocker(uint256 shareNumber)
        public
        view
        onlyStakeholders
        beLocked(shareNumber)
        returns (uint256 dueDate, address[] keyHolders)
    {
        dueDate = _lockers[shareNumber].dueDate;
        keyHolders = _lockers[shareNumber].keyHolders;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia)
        external
        view
        onlyBookeeper
        returns (bool)
    {
        IAgreement _ia = IAgreement(ia);

        uint8 qtyOfDeals = _ia.qtyOfDeals();

        for (uint8 i = 0; i < qtyOfDeals; i++) {
            (uint256 shareNumber, , , , , , , uint256 closingDate, , , ) = _ia
                .getDeal(i);

            if (!_isLocked[shareNumber]) continue;
            else if (_lockers[shareNumber].dueDate >= closingDate) return true;
        }

        return false;
    }

    function _isExempted(uint256 shareNumber, address[] consentParties)
        private
        view
        returns (bool)
    {
        if (!_isLocked[shareNumber]) return true;

        Locker storage locker = _lockers[shareNumber];

        if (locker.keyHolders.length > consentParties.length) {
            return false;
        } else {
            bool flag;
            for (uint256 j = 0; j < consentParties.length; j++) {
                flag = false;
                for (uint256 k = 0; k < locker.keyHolders.length; k++) {
                    if (locker.keyHolders[k] == consentParties[j]) {
                        flag = true;
                        break;
                    }
                }
                if (!flag) return false;
            }

            // address[] storage parties;
            // for (uint256 k = 0; k < consentParties.length; k++)
            //     parties.push(consentParties[k]);

            // for (uint256 i = 0; i < locker.keyHolders.length; i++) {
            //     (bool exist, ) = parties.firstIndexOf(locker.keyHolders[i]);
            //     if (!exist) {
            //         return false;
            //     }
            // }
            return true;
        }
    }

    function isExempted(address ia, uint8 snOfDeal)
        external
        view
        onlyBookeeper
        returns (bool)
    {
        (address[] memory consentParties, ) = _bom.getYea(ia);

        (uint256 shareNumber, , , , , , , , uint8 typeOfDeal, , ) = IAgreement(
            ia
        ).getDeal(snOfDeal);

        require(typeOfDeal == 2 || typeOfDeal == 3, "Not a ShareTransfer Deal");

        if (!_isExempted(shareNumber, consentParties)) return false;

        return true;
    }
}
