/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/ObjsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";

import "../../../common/components/ISigPage.sol";

import "./ILockUp.sol";

import "./ITerm.sol";

contract LockUp is ILockUp, ITerm, BOSSetting, BOMSetting {
    using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.SNList;
    using EnumerableSet for EnumerableSet.UintSet;

    // 股票锁定柜
    struct Locker {
        uint32 dueDate;
        EnumerableSet.UintSet keyHolders;
    }

    // 基准日条件未成就时，按“2277-09-19”设定到期日
    uint32 constant REMOTE_FUTURE = uint32(9710553600);

    // ssn => Locker
    mapping(uint32 => Locker) private _lockers;

    ObjsRepo.SNList private _ssnList;

    // ################
    // ##  Modifier  ##
    // ################

    modifier beLocked(uint32 ssn) {
        require(_ssnList.contains(ssn), "share NOT locked");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(bytes32 shareNumber, uint32 dueDate)
        external
        onlyAttorney
        shareExist(shareNumber.ssn())
    {
        _lockers[shareNumber.ssn()].dueDate = dueDate == 0
            ? REMOTE_FUTURE
            : dueDate;

        _ssnList.add(shareNumber);

        emit SetLocker(shareNumber, _lockers[shareNumber.ssn()].dueDate);
    }

    function delLocker(bytes32 shareNumber)
        external
        onlyAttorney
        beLocked(shareNumber.ssn())
    {
        delete _lockers[shareNumber.ssn()];

        _ssnList.remove(shareNumber);

        emit DelLocker(shareNumber);
    }

    function addKeyholder(bytes32 shareNumber, uint40 keyholder)
        external
        onlyAttorney
        beLocked(shareNumber.ssn())
    {
        if (_lockers[shareNumber.ssn()].keyHolders.add(keyholder)) {
            emit AddKeyholder(shareNumber, keyholder);
        }
    }

    function removeKeyholder(bytes32 shareNumber, uint40 keyholder)
        external
        onlyAttorney
        beLocked(shareNumber.ssn())
    {
        if (_lockers[shareNumber.ssn()].keyHolders.remove(keyholder)) {
            emit RemoveKeyholder(shareNumber, keyholder);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint32 ssn) external view returns (bool) {
        return _ssnList.contains(ssn);
    }

    function getLocker(uint32 ssn)
        public
        view
        beLocked(ssn)
        returns (uint32 dueDate, uint40[] keyHolders)
    {
        dueDate = _lockers[ssn].dueDate;
        keyHolders = _lockers[ssn].keyHolders.valuesToUint40();
    }

    function lockedShares() external view returns (bytes32[]) {
        return _ssnList.values();
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) external view returns (bool) {
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequence()
        );

        uint8 typeOfDeal = sn.typeOfDeal();
        uint32 ssn = sn.ssnOfDeal();

        if (
            typeOfDeal > 1 &&
            _ssnList.contains(ssn) &&
            _lockers[ssn].dueDate >= closingDate
        ) return true;

        return false;
    }

    function _isExempted(uint32 ssn, uint40[] agreedParties)
        private
        view
        returns (bool)
    {
        if (!_ssnList.contains(ssn)) return true;

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
        (uint40[] memory consentParties, ) = _bom.getYea(uint256(ia));

        uint40[] memory signers = ISigPage(ia).parties();

        uint40[] memory agreedParties = consentParties.combine(signers);

        uint32 ssn = sn.ssnOfDeal();

        return _isExempted(ssn, agreedParties);
    }
}
