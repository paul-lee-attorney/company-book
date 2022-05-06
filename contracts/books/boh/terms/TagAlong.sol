/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../../common/config/BOSSetting.sol";
import "../../../common/config/BOASetting.sol";
import "../../../common/config/BOMSetting.sol";
import "../../../common/config/DraftSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SafeMath.sol";
import "../../../common/lib/serialNumber/ShareSNParser.sol";
import "../../../common/lib/serialNumber/DealSNParser.sol";
import "../../../common/lib/serialNumber/TagRuleParser.sol";
import "../../../common/lib/serialNumber/SNFactory.sol";

import "../../../common/interfaces/IAgreement.sol";
import "../../../common/interfaces/ISigPage.sol";

// import "../../boa/AgreementCalculator.sol";

contract TagAlong is BOMSetting, BOSSetting, BOASetting, DraftSetting {
    using ArrayUtils for address[];
    using ArrayUtils for uint16[];
    // using SafeMath for uint256;
    // using SafeMath for uint8;
    using ShareSNParser for bytes32;
    using DealSNParser for bytes32;
    using TagRuleParser for bytes32;
    using SNFactory for bytes;

    struct Tag {
        mapping(uint16 => bool) isFollower;
        uint16[] followers;
        bytes32 rule;
    }

    // struct tagRule {
    //     uint16 drager;
    //     // 0-no condition; 1- biggest && shareRatio > threshold;
    //     uint8 triggerType;
    //     bool basedOnPar;
    //     // threshold to define material control party
    //     uint32 threshold;
    //     // false - free amount; true - pro rata (transfered parValue : original parValue)
    //     bool proRata;
    // }

    // drager => bool
    mapping(uint16 => bool) public isDrager;

    // drager => Tag
    mapping(uint16 => Tag) private _tags;

    mapping(uint16 => bool) private _exemptedGroups;

    // ################
    // ##   Event    ##
    // ################

    event SetTag(
        uint16 indexed drager,
        uint8 triggerType,
        bool basedOnPar,
        uint256 threshold,
        bool proRata
    );

    event AddFollower(uint16 indexed drager, address follower);

    event RemoveFollower(uint16 indexed drager, address follower);

    event DelTag(uint16 indexed drager);

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

    function _createTagRule(
        uint16 drager,
        uint8 triggerType,
        bool basedOnPar,
        uint32 threshold,
        bool proRata
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.sequenceToSN(0, drager);
        _sn[2] = bytes1(triggerType);
        _sn = _sn.boolToSN(3, basedOnPar);
        _sn = _sn.intToSN(4, threshold, 4);
        _sn = _sn.boolToSN(8, proRata);

        return _sn.bytesToBytes32();
    }

    function createTag(
        uint16 drager,
        uint8 triggerType,
        bool basedOnPar,
        uint32 threshold,
        bool proRata
    ) external onlyAttorney {
        require(triggerType < 4, "WRONG trigger type");
        require(threshold <= 5000, "WRONG ratio of threshold");
        require(_tags[drager].rule == bytes32(0), "tag rule ALREADY EXIST");

        bytes32 rule = _createTagRule(
            drager,
            triggerType,
            basedOnPar,
            threshold,
            proRata
        );

        isDrager[drager] = true;
        _tags[drager].rule = rule;

        emit SetTag(drager, triggerType, basedOnPar, threshold, proRata);
    }

    function addFollower(uint16 drager, uint16 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        require(!_tags[drager].isFollower[follower], "already followed");

        _tags[drager].isFollower[follower] = true;
        _tags[drager].followers.push(follower);

        emit AddFollower(drager, follower);
    }

    function removeFollower(uint16 drager, uint16 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        require(_tags[drager].isFollower[follower], "not followed");

        delete _tags[drager].isFollower[follower];

        _tags[drager].followers.removeByValue(follower);

        emit RemoveFollower(drager, follower);
    }

    function delTag(uint16 drager) external onlyAttorney dragerExist(drager) {
        delete _tags[drager];
        delete isDrager[drager];

        emit DelTag(drager);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function tagRule(uint16 drager)
        external
        view
        dragerExist(drager)
        returns (bytes32)
    {
        return _tags[drager].rule;
    }

    function isFollower(uint16 drager, uint16 follower)
        external
        view
        dragerExist(drager)
        returns (bool)
    {
        return _tags[drager].isFollower[follower];
    }

    function followers(uint16 drager)
        external
        view
        dragerExist(drager)
        returns (uint16[])
    {
        return _tags[drager].followers;
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
        if (sn.typeOfDeal() == 1) return false;

        address seller = IAgreement(ia)
            .shareNumberOfDeal(sn.sequenceOfDeal())
            .shareholder();

        uint16 groupNo = _bos.groupNo(seller);

        if (!isDrager[groupNo]) return false;

        bytes32 rule = _tags[groupNo].rule;

        if (rule.triggerTypeOfTag() == 0) return true;

        if (_bos.controller() != groupNo) return false;

        (, , bool isOrgController, , uint256 shareRatio) = _boa.topGroup(ia);

        if (!isOrgController) return true;

        if (shareRatio <= rule.thresholdOfTag()) return true;

        return false;
    }

    function isExempted(address ia, bytes32 sn)
        public
        onlyKeeper
        returns (bool)
    {
        require(_bom.isPassed(ia), "motion NOT passed");

        if (!isTriggered(ia, sn)) return true;

        (address[] memory consentParties, ) = _bom.getYea(ia);

        uint256 i;

        for (i = 0; i < consentParties.length; i++)
            _exemptedGroups[_bos.groupNo(consentParties[i])] = true;

        address[] memory signers = ISigPage(ia).signers();

        for (i = 0; i < signers.length; i++)
            _exemptedGroups[_bos.groupNo(signers[i])] = true;

        uint16[] memory rightholders = _tags[
            _bos.groupNo(
                IAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder()
            )
        ].followers;

        for (i = 0; i < rightholders.length; i++)
            if (!_exemptedGroups[rightholders[i]]) return false;

        return true;
    }
}
