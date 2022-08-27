/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/IInvestmentAgreement.sol";
import "../../boa/IMockResults.sol";

import "../../../common/components/IDocumentsRepo.sol";

import "../../../common/ruting/BOCSetting.sol";
import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOASetting.sol";

import "../../../common/lib/SNParser.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/EnumsRepo.sol";

import "./IAlongs.sol";

contract DragAlong is IAlongs, BOCSetting, BOSSetting, BOASetting {
    using SNParser for bytes32;
    using SNFactory for bytes;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Link {
        EnumerableSet.UintSet followers;
        bytes32 rule;
    }

    // struct linkRule {
    //     uint16 drager;
    //     // 0-no condition; 1- not biggest || biggest but shareRatio < threshold; 2- 1 && price >= uintPrice; 3- 1 && roe >= ROE
    //     uint8 triggerType;
    //     // threshold to define material control party
    //     uint32 threshold;
    //     // false - free amount; true - pro rata (transfered parValue : original parValue)
    //     bool proRata;
    //     uint32 unitPrice;
    //     uint32 ROE;
    // }

    EnumerableSet.UintSet private _dragers;

    // drager => Link
    mapping(uint16 => Link) internal _links;

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerExist(uint16 group) {
        require(_dragers.contains(group), "WRONG drager ID");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createLinkRule(
        uint16 drager,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, drager);
        _sn[2] = bytes1(triggerType);
        _sn = _sn.intToSN(3, threshold, 4);
        _sn = _sn.boolToSN(7, proRata);
        _sn = _sn.dateToSN(8, unitPrice);
        _sn = _sn.dateToSN(12, roe);

        return _sn.bytesToBytes32();
    }

    function createLink(
        uint16 drager,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) external onlyAttorney {
        require(triggerType < 4, "WRONG trigger type");
        require(threshold <= 5000, "WRONG ratio of threshold");
        require(_links[drager].rule == bytes32(0), "tag rule ALREADY EXIST");

        bytes32 rule = _createLinkRule(
            drager,
            triggerType,
            threshold,
            proRata,
            unitPrice,
            roe
        );

        _dragers.add(drager);

        _links[drager].rule = rule;

        emit SetLink(drager, rule);
    }

    function addFollower(uint16 drager, uint16 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        if (_links[drager].followers.add(follower))
            emit AddFollower(drager, follower);
    }

    function removeFollower(uint16 drager, uint16 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        if (_links[drager].followers.remove(follower))
            emit RemoveFollower(drager, follower);
    }

    function delLink(uint16 drager) external onlyAttorney dragerExist(drager) {
        delete _links[drager];

        _dragers.remove(drager);

        emit DelLink(drager);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint16 drager)
        external
        view
        dragerExist(drager)
        returns (bytes32)
    {
        return _links[drager].rule;
    }

    function isDrager(uint16 drager) external view returns (bool) {
        return _dragers.contains(drager);
    }

    function isFollower(uint16 drager, uint16 follower)
        public
        view
        dragerExist(drager)
        returns (bool)
    {
        return _links[drager].followers.contains(follower);
    }

    function isLinked(uint40 usrDrager, uint40 usrFollower)
        public
        view
        returns (bool)
    {
        uint16 drager = _boc.groupNo(usrDrager);
        uint16 follower = _boc.groupNo(usrFollower);

        return isFollower(drager, follower);
    }

    function dragers() external view returns (uint16[]) {
        return _dragers.valuesToUint16();
    }

    function followers(uint16 drager)
        external
        view
        dragerExist(drager)
        returns (uint16[])
    {
        return _links[drager].followers.valuesToUint16();
    }

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view onlyKeeper returns (bool) {
        require(isTriggered(ia, sn), "not triggered");

        // uint40 drager = IInvestmentAgreement(ia)
        //     .shareNumberOfDeal(sn.sequence())
        //     .shareholder();

        // require(caller == drager, "caller is not drager of DragAlong");

        // require(
        //     isLinked(caller, shareNumber.shareholder()),
        //     "caller and target shareholder NOT linked"
        // );

        uint32 dealPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequence()
        );

        bytes32 rule = _links[_boc.groupNo(caller)].rule;

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

        (, , , , uint32 issuePrice, ) = _bos.getShare(shareNumber.ssn());
        uint32 issueDate = shareNumber.issueDate();

        if (
            _roeOfDeal(dealPrice, issuePrice, closingDate, issueDate) >=
            rule.roeOfLink()
        ) return true;

        return false;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool) {
        if (
            IDocumentsRepo(_boa).currentState(ia) !=
            uint8(EnumsRepo.BODStates.Circulated)
        ) return false;

        if (sn.typeOfDeal() <= uint8(EnumsRepo.TypeOfDeal.PreEmptive))
            return false;

        uint40 seller = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequence())
            .shareholder();

        uint16 sellerGroup = _boc.groupNo(seller);

        if (!_dragers.contains(sellerGroup)) return false;

        bytes32 rule = _links[sellerGroup].rule;

        if (
            rule.triggerTypeOfLink() ==
            uint8(EnumsRepo.TriggerTypeOfAlongs.NoConditions)
        ) return true;

        if (_boc.controller() != sellerGroup) return false;

        (, , bool isOrgController, uint16 shareRatio, ) = IMockResults(
            _boa.mockResultsOfIA(ia)
        ).topGroup();

        if (!isOrgController) return true;

        if (shareRatio <= rule.thresholdOfLink()) return true;

        return false;
    }

    function _roeOfDeal(
        uint32 dealPrice,
        uint32 issuePrice,
        uint32 closingDate,
        uint32 issueDateOfShare
    ) internal pure returns (uint16 roe) {
        require(dealPrice > issuePrice, "NEGATIVE selling price");
        require(closingDate > issueDateOfShare, "NEGATIVE holding period");

        uint32 deltaPrice = dealPrice - issuePrice;
        uint32 deltaDate = closingDate - issueDateOfShare;

        roe = uint16(
            (((deltaPrice * 10000) / issuePrice) * 31536000) / deltaDate
        );
    }
}
