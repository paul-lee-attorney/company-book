/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/interfaces/IAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOMSetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";

import "../../../common/components/interfaces/ISigPage.sol";

// import "../../../common/interfaces/IMotion.sol";

contract LockUp is BOSSetting, BOMSetting, DraftControl {
    using ArrayUtils for uint256[];
    using ArrayUtils for uint32[];
    using SNParser for bytes32;

    // 股票锁定柜
    struct Locker {
        uint256 dueDate;
        uint32[] keyHolders;
    }

    // 基准日条件未成就时，按“2277-09-19”设定到期日
    uint256 constant REMOTE_FUTURE = 9710553600;

    // ssn => Locker
    mapping(bytes6 => Locker) private _lockers;

    // ssn => bool
    mapping(bytes6 => bool) public isLocked;

    // ################
    // ##   Event   ##
    // ################

    event SetLocker(bytes6 indexed ssn, uint256 dueDate);

    event AddKeyholder(bytes6 indexed ssn, uint32 keyholder);

    event RemoveKeyholder(bytes6 indexed ssn, uint32 keyholder);

    event DelLocker(bytes6 indexed ssn);

    // ################
    // ##  Modifier  ##
    // ################

    modifier beLocked(bytes6 ssn) {
        require(isLocked[ssn], "share NOT locked");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(bytes6 ssn, uint256 dueDate)
        external
        onlyAttorney
        shareExist(ssn)
    {
        _lockers[ssn].dueDate = dueDate == 0 ? REMOTE_FUTURE : dueDate;
        isLocked[ssn] = true;

        emit SetLocker(ssn, _lockers[ssn].dueDate);
    }

    function delLocker(bytes6 ssn) external onlyAttorney beLocked(ssn) {
        delete _lockers[ssn];
        isLocked[ssn] = false;

        emit DelLocker(ssn);
    }

    function addKeyholder(bytes6 ssn, uint32 keyholder)
        external
        onlyAttorney
        beLocked(ssn)
    {
        (bool exist, ) = _lockers[ssn].keyHolders.firstIndexOf(keyholder);

        if (!exist) {
            _lockers[ssn].keyHolders.push(keyholder);
            emit AddKeyholder(ssn, keyholder);
        }
    }

    function removeKeyholder(bytes6 ssn, uint32 keyholder)
        external
        onlyAttorney
        beLocked(ssn)
    {
        (bool exist, ) = _lockers[ssn].keyHolders.firstIndexOf(keyholder);

        if (exist) {
            _lockers[ssn].keyHolders.removeByValue(keyholder);
            emit RemoveKeyholder(ssn, keyholder);
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getLocker(bytes6 ssn)
        public
        view
        beLocked(ssn)
        returns (uint256 dueDate, uint32[] keyHolders)
    {
        dueDate = _lockers[ssn].dueDate;
        keyHolders = _lockers[ssn].keyHolders;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn)
        external
        view
        onlyKeeper
        returns (bool)
    {
        (, , , , uint256 closingDate, , ) = IAgreement(ia).getDeal(
            sn.sequenceOfDeal()
        );

        uint8 typeOfDeal = sn.typeOfDeal();
        bytes6 ssn = sn.shortShareNumberOfDeal();

        if (
            typeOfDeal > 1 &&
            isLocked[ssn] &&
            _lockers[ssn].dueDate >= closingDate
        ) return true;

        return false;
    }

    function _isExempted(bytes6 ssn, uint32[] agreedParties)
        private
        view
        returns (bool)
    {
        if (!isLocked[ssn]) return true;

        Locker storage locker = _lockers[ssn];

        if (locker.keyHolders.length > agreedParties.length) {
            return false;
        } else {
            bool flag;
            for (uint256 j = 0; j < locker.keyHolders.length; j++) {
                flag = false;
                for (uint256 k = 0; k < agreedParties.length; k++) {
                    if (locker.keyHolders[j] == agreedParties[k]) {
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
        onlyKeeper
        returns (bool)
    {
        (uint32[] memory consentParties, ) = _bom.getYea(ia);

        uint32[] memory signers = ISigPage(ia).signers();

        uint256 len = consentParties.length + signers.length;

        uint32[] memory agreedParties = new uint32[](len);

        uint256 i;

        for (i = 0; i < consentParties.length; i++)
            agreedParties[i] = consentParties[i];
        for (i = 0; i < signers.length; i++)
            agreedParties[len - 1 - i] = signers[i];

        bytes6 ssn = sn.shortShareNumberOfDeal();

        return _isExempted(ssn, agreedParties);
    }
}
