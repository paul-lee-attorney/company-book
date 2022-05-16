/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/interfaces/IAgreement.sol";

import "../../../common/config/BOSSetting.sol";
import "../../../common/config/BOASetting.sol";
import "../../../common/config/DraftSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SafeMath.sol";

import "../../../common/lib/serialNumber/ShareSNParser.sol";
import "../../../common/lib/serialNumber/DealSNParser.sol";
import "../../../common/lib/serialNumber/LinkRuleParser.sol";
import "../../../common/lib/serialNumber/SNFactory.sol";

contract DragAlong is BOSSetting, BOASetting, DraftSetting {
    using ArrayUtils for address[];
    using ArrayUtils for uint16[];
    using SafeMath for uint256;
    // using SafeMath for uint8;
    using ShareSNParser for bytes32;
    using DealSNParser for bytes32;
    using LinkRuleParser for bytes32;
    using SNFactory for bytes;

    struct Link {
        mapping(uint16 => bool) isFollower;
        uint16[] followers;
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

    // drager => bool
    mapping(uint16 => bool) public isDrager;

    // drager => Link
    mapping(uint16 => Link) internal _links;

    // ################
    // ##   Event    ##
    // ################

    event SetLink(uint16 indexed drager, bytes32 rule);

    event AddFollower(uint16 indexed drager, address follower);

    event RemoveFollower(uint16 indexed drager, address follower);

    event DelLink(uint16 indexed drager);

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerExist(uint16 drager) {
        require(isDrager[drager], "WRONG drager ID");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createLinkRule(
        uint16 drager,
        uint8 triggerType,
        bool basedOnPar,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, drager);
        _sn[2] = bytes1(triggerType);
        _sn = _sn.boolToSN(3, basedOnPar);
        _sn = _sn.intToSN(4, threshold, 4);
        _sn = _sn.boolToSN(8, proRata);
        _sn = _sn.dateToSN(9, unitPrice);
        _sn = _sn.dateToSN(13, roe);

        return _sn.bytesToBytes32();
    }

    function createLink(
        uint16 drager,
        uint8 triggerType,
        bool basedOnPar,
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
            basedOnPar,
            threshold,
            proRata,
            unitPrice,
            roe
        );

        isDrager[drager] = true;
        _links[drager].rule = rule;

        emit SetLink(drager, rule);
    }

    function addFollower(uint16 drager, uint16 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        require(!_links[drager].isFollower[follower], "already followed");

        _links[drager].isFollower[follower] = true;
        _links[drager].followers.push(follower);

        emit AddFollower(drager, follower);
    }

    function removeFollower(uint16 drager, uint16 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        require(_links[drager].isFollower[follower], "not followed");

        delete _links[drager].isFollower[follower];

        _links[drager].followers.removeByValue(follower);

        emit RemoveFollower(drager, follower);
    }

    function delLink(uint16 drager) external onlyAttorney dragerExist(drager) {
        delete _links[drager];
        delete isDrager[drager];

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

    function isFollower(uint16 drager, uint16 follower)
        public
        view
        onlyKeeper
        dragerExist(drager)
        returns (bool)
    {
        return _links[drager].isFollower[follower];
    }

    function isLinked(address dragerAddr, address followerAddr)
        external
        view
        onlyKeeper
        returns (bool)
    {
        uint16 drager = _bos.groupNo(dragerAddr);
        uint16 follower = _bos.groupNo(followerAddr);

        return isFollower(drager, follower);
    }

    function followers(uint16 drager)
        external
        view
        dragerExist(drager)
        returns (uint16[])
    {
        return _links[drager].followers;
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
        if (!_boa.isSubmitted(ia)) return false;

        if (sn.typeOfDeal() == 1) return false;

        address seller = IAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        // (, uint256 dealPrice, , , uint32 closingDate, , ) = IAgreement(ia)
        //     .getDeal(sn.sequenceOfDeal());

        uint16 sellerGroup = _bos.groupNo(seller);

        if (!isDrager[sellerGroup]) return false;

        bytes32 rule = _links[sellerGroup].rule;

        if (rule.triggerTypeOfLink() == 0) return true;

        // if (rule.triggerTypeOfLink() == 2 && dealPrice < rule.unitPriceOfLink())
        //     return false;

        if (_bos.controller() != sellerGroup) return false;

        (, , bool isOrgController, , uint256 shareRatio) = _boa.topGroup(ia);

        if (!isOrgController) return true;

        if (shareRatio <= rule.thresholdOfLink()) return true;

        return false;
    }

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber
    ) public view onlyKeeper returns (bool) {
        (, uint256 dealPrice, , , uint32 closingDate, , ) = IAgreement(ia)
            .getDeal(sn.sequenceOfDeal());

        bytes32 rule = _links[
            _bos.groupNo(
                IAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder()
            )
        ].rule;

        if (rule.triggerTypeOfLink() < 2) return true;

        if (rule.triggerTypeOfLink() == 2) {
            if (dealPrice >= rule.unitPriceOfLink()) return true;
            else return false;
        }

        (, , , , , uint256 issuePrice, ) = _bos.getShare(shareNumber.short());
        uint32 issueDate = shareNumber.issueDate();

        if (
            dealPrice.roeOfDeal(issuePrice, closingDate, issueDate) >=
            rule.roeOfLink()
        ) return true;

        return false;
    }
}
