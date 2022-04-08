/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/BOSSetting.sol";
import "../common/config/BOMSetting.sol";
import "../common/config/DraftSetting.sol";

import "../common/lib/ArrayUtils.sol";

import "../common/interfaces/IAgreement.sol";
import "../common/interfaces/ISigPage.sol";

// import "../common/interfaces/IMotion.sol";

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
    mapping(bytes32 => Locker) private _lockers;

    // shareNumber => bool
    mapping(bytes32 => bool) public isLocked;

    // ################
    // ##   Event   ##
    // ################

    event SetLocker(bytes32 indexed shareNumber, uint256 dueDate);

    event AddKeyholder(bytes32 indexed shareNumber, address keyholder);

    event RemoveKeyholder(bytes32 indexed shareNumber, address keyholder);

    event DelLocker(bytes32 indexed shareNumber);

    // ################
    // ##  Modifier  ##
    // ################

    modifier beLocked(bytes32 shareNumber) {
        require(isLocked[shareNumber], "share NOT locked");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(bytes32 shareNumber, uint256 dueDate)
        external
        onlyAttorney
        beShare(shareNumber)
    {
        _lockers[shareNumber].dueDate = dueDate == 0 ? REMOTE_FUTURE : dueDate;
        _isLocked[shareNumber] = true;

        emit SetLocker(shareNumber, _lockers[shareNumber].dueDate);
    }

    function delLocker(bytes32 shareNumber)
        external
        onlyAttorney
        beLocked(shareNumber)
    {
        delete _lockers[shareNumber];
        _isLocked[shareNumber] = false;

        emit DelLocker(shareNumber);
    }

    function addKeyholder(bytes32 shareNumber, address keyholder)
        external
        onlyAttorney
        beLocked(shareNumber)
    {
        (bool exist, ) = _lockers[shareNumber].keyHolders.firstIndexOf(
            keyholder
        );

        if (!exist) {
            _lockers[shareNumber].keyHolders.push(keyholder);
            emit AddKeyholder(shareNumber, keyholder);
        }
    }

    function removeKeyholder(bytes32 shareNumber, address keyholder)
        external
        onlyAttorney
        beLocked(shareNumber)
    {
        (bool exist, ) = _lockers[shareNumber].keyHolders.firstIndexOf(
            keyholder
        );

        if (exist) {
            _lockers[shareNumber].keyholders.removeByValue(keyholder);
            emit RemoveKeyholder(shareNumber, keyholder);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getLocker(bytes32 shareNumber)
        public
        view
        beLocked(shareNumber)
        returns (uint256 dueDate, address[] keyHolders)
    {
        dueDate = _lockers[shareNumber].dueDate;
        keyHolders = _lockers[shareNumber].keyHolders;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        external
        view
        onlyBookeeper
        returns (bool)
    {
        (, , , uint256 closingDate, , ) = IAgreement(ia).getDeal(sn);

        (uint8 typeOfDeal, bytes32 shareNumber, , , ) = IAgreement(ia).parseSN(
            sn
        );

        if (
            typeOfDeal > 1 &&
            isLocked[shareNumber] &&
            _lockers[shareNumber].dueDate >= closingDate
        ) return true;

        return false;
    }

    function _isExempted(bytes32 shareNumber, address[] consentParties)
        private
        view
        returns (bool)
    {
        if (!isLocked[shareNumber]) return true;

        Locker storage locker = _lockers[shareNumber];

        if (locker.keyHolders.length > consentParties.length) {
            return false;
        } else {
            bool flag;
            for (uint256 j = 0; j < locker.keyHolders.length; j++) {
                flag = false;
                for (uint256 k = 0; k < consentParties.length; k++) {
                    if (locker.keyHolders[j] == consentParties[k]) {
                        flag = true;
                        break;
                    }
                }
                if (!flag) return false;
            }

            return true;
        }
    }

    function isExempted(address ia, bytes32 sn)
        external
        view
        onlyBookeeper
        returns (bool)
    {
        (address[] memory consentParties, ) = _bom.getYea(ia);

        (, bytes32 shareNumber, , , ) = IAgreement(ia).parseSN(sn);

        return _isExempted(shareNumber, consentParties);
    }
}
