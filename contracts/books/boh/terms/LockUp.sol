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
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/ObjsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";

import "../../../common/components/ISigPage.sol";

import "./ILockUp.sol";

import "./ITerm.sol";

contract LockUp is ILockUp, ITerm, BOSSetting, BOMSetting, DraftControl {
    using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.SNList;
    using EnumerableSet for EnumerableSet.UintSet;

    // 股票锁定柜
    struct Locker {
        uint256 dueDate;
        EnumerableSet.UintSet keyHolders;
    }

    // 基准日条件未成就时，按“2277-09-19”设定到期日
    uint256 constant REMOTE_FUTURE = 9710553600;

    // ssn => Locker
    mapping(bytes6 => Locker) private _lockers;

    ObjsRepo.SNList private _ssnList;

    // ################
    // ##  Modifier  ##
    // ################

    modifier beLocked(bytes6 ssn) {
        require(_ssnList.contains(ssn), "share NOT locked");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(bytes32 shareNumber, uint256 dueDate)
        external
        onlyAttorney
        shareExist(shareNumber.short())
    {
        _lockers[shareNumber.short()].dueDate = dueDate == 0
            ? REMOTE_FUTURE
            : dueDate;

        _ssnList.add(shareNumber);

        emit SetLocker(shareNumber, _lockers[shareNumber.short()].dueDate);
    }

    function delLocker(bytes32 shareNumber)
        external
        onlyAttorney
        beLocked(shareNumber.short())
    {
        delete _lockers[shareNumber.short()];

        _ssnList.remove(shareNumber);

        emit DelLocker(shareNumber.short());
    }

    function addKeyholder(bytes32 shareNumber, uint40 keyholder)
        external
        onlyAttorney
        beLocked(shareNumber.short())
    {
        if (_lockers[shareNumber.short()].keyHolders.add(keyholder)) {
            emit AddKeyholder(shareNumber, keyholder);
        }
    }

    function removeKeyholder(bytes32 shareNumber, uint40 keyholder)
        external
        onlyAttorney
        beLocked(shareNumber.short())
    {
        if (_lockers[shareNumber.short()].keyHolders.remove(keyholder)) {
            emit RemoveKeyholder(shareNumber, keyholder);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(bytes6 ssn) external view onlyUser returns (bool) {
        return _ssnList.contains(ssn);
    }

    function getLocker(bytes6 ssn)
        public
        view
        beLocked(ssn)
        onlyUser
        returns (uint256 dueDate, uint40[] keyHolders)
    {
        dueDate = _lockers[ssn].dueDate;
        keyHolders = _lockers[ssn].keyHolders.valuesToUint40();
    }

    function lockedShares() external view onlyUser returns (bytes32[]) {
        return _ssnList.values();
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        external
        view
        onlyUser
        returns (bool)
    {
        uint256 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequence()
        );

        uint8 typeOfDeal = sn.typeOfDeal();
        bytes6 ssn = sn.shortShareNumberOfDeal();

        if (
            typeOfDeal > 1 &&
            _ssnList.contains(ssn) &&
            _lockers[ssn].dueDate >= closingDate
        ) return true;

        return false;
    }

    function _isExempted(bytes6 ssn, uint40[] agreedParties)
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

    function isExempted(address ia, bytes32 sn)
        external
        view
        onlyUser
        returns (bool)
    {
        (uint40[] memory consentParties, ) = _bom.getYea(uint256(ia));

        uint40[] memory signers = ISigPage(ia).parties();

        uint40[] memory agreedParties = consentParties.combine(signers);

        bytes6 ssn = sn.shortShareNumberOfDeal();

        return _isExempted(ssn, agreedParties);
    }
}
