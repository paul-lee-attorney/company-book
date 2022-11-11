// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOMSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";

import "../../../common/components/ISigPage.sol";

import "./ILockUp.sol";

import "./ITerm.sol";

contract LockUp is ILockUp, ITerm, BOMSetting {
    using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // 股票锁定柜
    struct Locker {
        uint32 ssn; // short share number
        uint32 dueDate;
        uint32 prev;
        uint32 next;
        EnumerableSet.UintSet keyHolders;
    }

    /*
    lockers[0] {
        ssn: qtyOfLockers;
        uint32 (null);
        uint32 tail;
        uint32 head;
        keyHolders: (null);
    }
*/

    // 基准日条件未成就时，按“2105-09-19”设定到期日
    uint32 constant REMOTE_FUTURE = 4282732800;

    // ssn => Locker
    mapping(uint256 => Locker) private _lockers;

    // ################
    // ##  Modifier  ##
    // ################

    modifier beLocked(uint32 ssn) {
        require(isLocked(ssn), "share NOT locked");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(uint32 ssn, uint32 dueDate) external onlyAttorney {
        _lockers[ssn].ssn = ssn;
        _lockers[ssn].dueDate = dueDate == 0 ? REMOTE_FUTURE : dueDate;

        uint32 tail = _lockers[0].prev;

        _lockers[tail].next = ssn;
        _lockers[ssn].prev = tail;

        _lockers[0].prev = ssn;

        _lockers[0].ssn++;

        emit SetLocker(ssn, _lockers[ssn].dueDate);
    }

    function updateLocker(uint32 ssn, uint32 dueDate)
        external
        onlyManager(1)
        beLocked(ssn)
    {
        Locker storage l = _lockers[ssn];

        require(
            l.dueDate == REMOTE_FUTURE,
            "LU.updateLocker: not a REMOTE_FUTURE Locker"
        );

        l.dueDate = dueDate;

        emit UpdateLocker(ssn, dueDate);
    }

    function delLocker(uint32 ssn) external onlyAttorney beLocked(ssn) {
        Locker storage l = _lockers[ssn];

        _lockers[l.prev].next = l.next;
        _lockers[l.next].prev = l.prev;

        delete _lockers[ssn];

        _lockers[0].ssn--;

        emit DelLocker(ssn);
    }

    function addKeyholder(uint32 ssn, uint40 keyholder)
        external
        onlyAttorney
        beLocked(ssn)
    {
        if (_lockers[ssn].keyHolders.add(keyholder)) {
            emit AddKeyholder(ssn, keyholder);
        }
    }

    function removeKeyholder(uint32 ssn, uint40 keyholder)
        external
        onlyAttorney
        beLocked(ssn)
    {
        if (_lockers[ssn].keyHolders.remove(keyholder)) {
            emit RemoveKeyholder(ssn, keyholder);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint32 ssn) public view returns (bool) {
        return ssn > 0 && _lockers[ssn].ssn == ssn;
    }

    function getLocker(uint32 ssn)
        public
        view
        beLocked(ssn)
        returns (uint32 dueDate, uint40[] memory keyHolders)
    {
        dueDate = _lockers[ssn].dueDate;
        keyHolders = _lockers[ssn].keyHolders.valuesToUint40();
    }

    function lockedShares() external view returns (uint32[] memory) {
        uint32[] memory list = new uint32[](_lockers[0].ssn);

        uint256 i = 0;
        uint32 cur = _lockers[0].next;
        while (cur > 0) {
            list[i] = _lockers[cur].ssn;
            cur = _lockers[cur].next;
            i++;
        }

        return list;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) external view returns (bool) {
        uint32 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            sn.sequence()
        );

        uint8 typeOfDeal = sn.typeOfDeal();
        uint32 ssn = sn.ssnOfDeal();

        if (
            typeOfDeal > 1 &&
            isLocked(ssn) &&
            _lockers[ssn].dueDate >= closingDate
        ) return true;

        return false;
    }

    function _isExempted(uint32 ssn, uint40[] memory agreedParties)
        private
        view
        returns (bool)
    {
        if (!isLocked(ssn)) return true;

        Locker storage locker = _lockers[ssn];

        uint40[] memory holders = locker.keyHolders.valuesToUint40();
        uint256 len = holders.length;

        if (len > agreedParties.length) {
            return false;
        } else {
            return holders.fullyCoveredBy(agreedParties);
        }
    }

    function isExempted(address ia, bytes32 sn) external view returns (bool) {
        (uint40[] memory consentParties, ) = _bom.getYea(uint256(uint160(ia)));

        uint40[] memory signers = ISigPage(ia).partiesOfDoc();

        uint40[] memory agreedParties = consentParties.combine(signers);

        uint32 ssn = sn.ssnOfDeal();

        return _isExempted(ssn, agreedParties);
    }
}
