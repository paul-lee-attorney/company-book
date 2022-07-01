/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOASetting.sol";
import "../../../common/access/DraftControl.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/EnumsRepo.sol";

import "./IAlongs.sol";

contract DragAlong is IAlongs, BOSSetting, BOASetting, DraftControl {
    using ArrayUtils for address[];
    // using ArrayUtils for uint16[];
    using SNParser for bytes32;
    using SNFactory for bytes;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Link {
        EnumerableSet.UintSet followerGroups;
        bytes32 rule;
    }

    // struct linkRule {
    //     uint16 drager;
    //     // 0-no condition; 1- not biggest || biggest but shareRatio < threshold; 2- 1 && price >= uintPrice; 3- 1 && roe >= ROE
    //     uint8 triggerType;
    //     bool basedOnPar;
    //     // threshold to define material control party
    //     uint32 threshold;
    //     // false - free amount; true - pro rata (transfered parValue : original parValue)
    //     bool proRata;
    //     uint32 unitPrice;
    //     uint32 ROE;
    // }

    EnumerableSet.UintSet private _dragerGroups;

    // dragerGroup => Link
    mapping(uint16 => Link) internal _links;

    // ################
    // ##   Event    ##
    // ################

    event SetLink(uint16 indexed dragerGroup, bytes32 rule);

    event AddFollower(uint16 indexed dragerGroup, uint16 followerGroup);

    event RemoveFollower(uint16 indexed dragerGroup, uint16 followerGroup);

    event DelLink(uint16 indexed dragerGroup);

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerGroupExist(uint16 group) {
        require(_dragerGroups.contains(uint256(group)), "WRONG drager ID");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createLinkRule(
        uint16 dragerGroup,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, dragerGroup);
        _sn[2] = bytes1(triggerType);
        _sn = _sn.intToSN(3, threshold, 4);
        _sn = _sn.boolToSN(7, proRata);
        _sn = _sn.dateToSN(8, unitPrice);
        _sn = _sn.dateToSN(12, roe);

        return _sn.bytesToBytes32();
    }

    function createLink(
        uint16 dragerGroup,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) external onlyAttorney {
        require(triggerType < 4, "WRONG trigger type");
        require(threshold <= 5000, "WRONG ratio of threshold");
        require(
            _links[dragerGroup].rule == bytes32(0),
            "tag rule ALREADY EXIST"
        );

        bytes32 rule = _createLinkRule(
            dragerGroup,
            triggerType,
            threshold,
            proRata,
            unitPrice,
            roe
        );

        _dragerGroups.add(uint256(dragerGroup));

        _links[dragerGroup].rule = rule;

        emit SetLink(dragerGroup, rule);
    }

    function addFollowerGroup(uint16 dragerGroup, uint16 followerGroup)
        external
        onlyAttorney
        dragerGroupExist(dragerGroup)
    {
        if (_links[dragerGroup].followerGroups.add(uint256(followerGroup)))
            emit AddFollower(dragerGroup, followerGroup);
    }

    function removeFollower(uint16 dragerGroup, uint16 followerGroup)
        external
        onlyAttorney
        dragerGroupExist(dragerGroup)
    {
        if (_links[dragerGroup].followerGroups.remove(uint256(followerGroup)))
            emit RemoveFollower(dragerGroup, followerGroup);
    }

    function delLink(uint16 dragerGroup)
        external
        onlyAttorney
        dragerGroupExist(dragerGroup)
    {
        delete _links[dragerGroup];

        _dragerGroups.remove(uint256(dragerGroup));
        // delete _isDragerGroup[dragerGroup];

        emit DelLink(dragerGroup);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint16 dragerGroup)
        external
        view
        dragerGroupExist(dragerGroup)
        onlyUser
        returns (bytes32)
    {
        return _links[dragerGroup].rule;
    }

    function isFollowerGroup(uint16 dragerGroup, uint16 followerGroup)
        public
        view
        onlyUser
        dragerGroupExist(dragerGroup)
        returns (bool)
    {
        return
            _links[dragerGroup].followerGroups.contains(uint256(followerGroup));
    }

    function isLinked(uint40 drager, uint40 follower)
        public
        view
        onlyUser
        returns (bool)
    {
        uint16 dragerGroup = _bos.groupNo(drager);
        uint16 followerGroup = _bos.groupNo(follower);

        return isFollowerGroup(dragerGroup, followerGroup);
    }

    function isDragerGroup(uint16 group) external view onlyUser returns (bool) {
        return _dragerGroups.contains(uint256(group));
    }

    function dragerGroups() external view onlyUser returns (uint16[]) {
        return _dragerGroups.valuesToUint16();
    }

    function followerGroups(uint16 dragerGroup)
        external
        view
        dragerGroupExist(dragerGroup)
        onlyUser
        returns (uint16[])
    {
        return _links[dragerGroup].followerGroups.valuesToUint16();
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
        if (_boa.currentState(ia) != uint8(EnumsRepo.BODStates.Circulated))
            return false;

        if (sn.typeOfDeal() <= uint8(EnumsRepo.TypeOfDeal.PreEmptive))
            return false;

        uint40 seller = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        uint16 sellerGroup = _bos.groupNo(seller);

        if (!_dragerGroups.contains(uint256(sellerGroup))) return false;

        bytes32 rule = _links[sellerGroup].rule;

        if (
            rule.triggerTypeOfLink() ==
            uint8(EnumsRepo.TriggerTypeOfAlongs.NoConditions)
        ) return true;

        if (_bos.controller() != sellerGroup) return false;

        (, , bool isOrgController, , uint256 shareRatio) = _boa.topGroup(ia);

        if (!isOrgController) return true;

        if (shareRatio <= rule.thresholdOfLink()) return true;

        return false;
    }

    function _roeOfDeal(
        uint256 dealPrice,
        uint256 issuePrice,
        uint32 closingDate,
        uint32 issueDateOfShare
    ) internal pure returns (uint256 roe) {
        require(dealPrice > issuePrice, "NEGATIVE selling price");
        require(closingDate > issueDateOfShare, "NEGATIVE holding period");

        uint256 deltaPrice = dealPrice - issuePrice;
        uint32 deltaDate = closingDate - issueDateOfShare;

        roe =
            (deltaPrice * 365000000) /
            (issuePrice * (uint256(deltaDate) / 864));
    }

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) public view onlyKeeper returns (bool) {
        require(isTriggered(ia, sn), "not triggered");

        uint40 drager = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        require(caller == drager, "caller is not drager of DragAlong");

        require(
            isLinked(caller, shareNumber.shareholder()),
            "caller and target shareholder NOT linked"
        );

        uint256 dealPrice = IInvestmentAgreement(ia).unitPrice(
            sn.sequenceOfDeal()
        );
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequenceOfDeal()
        );

        bytes32 rule = _links[_bos.groupNo(drager)].rule;

        if (
            rule.triggerTypeOfLink() <
            uint8(EnumsRepo.TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) return true;

        if (
            rule.triggerTypeOfLink() ==
            uint8(EnumsRepo.TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) {
            if (dealPrice >= rule.unitPriceOfLink()) return true;
            else return false;
        }

        (, , , , uint256 issuePrice, ) = _bos.getShare(shareNumber.short());
        uint32 issueDate = shareNumber.issueDate();

        if (
            _roeOfDeal(dealPrice, issuePrice, closingDate, issueDate) >=
            rule.roeOfLink()
        ) return true;

        return false;
    }
}
