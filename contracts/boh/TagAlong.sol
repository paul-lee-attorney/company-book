/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";
import "../config/BOMSetting.sol";
import "../config/DraftSetting.sol";

import "../lib/ArrayUtils.sol";
import "../lib/SafeMath.sol";

import "../interfaces/IAgreement.sol";
import "../interfaces/ISigPage.sol";

import "./Groups.sol";

// import "../interfaces/IMotion.sol";

contract TagAlong is BOSSetting, BOMSetting, Groups {
    using ArrayUtils for address[];
    using SafeMath for uint256;
    using SafeMath for uint8;

    struct Tag {
        // address of follower;
        address[] followers;
        // 0-no condition; 1-ratio>50%; 2-(biggest ratio & >= threshold); 3-biggest shareholder (ratio < threshold)
        uint8 triggerType;
        // threshold to define material control party
        uint256 threshold;
        // false - free amount; true - pro rata (transfered parValue : original parValue)
        bool proRata;
    }

    // dragerGroupID => Tag
    mapping(uint8 => Tag) private _tags;
    // dragerGroupID => bool
    mapping(uint8 => bool) public isDrager;

    // ################
    // ##   Event    ##
    // ################

    event SetTag(
        uint8 indexed dragerID,
        uint8 triggerType,
        uint256 threshold,
        bool proRata
    );

    event AddFollower(uint8 indexed dragerID, address follower);

    event RemoveFollower(uint8 indexed dragerID, address follower);

    event DelTag(uint8 indexed dragerID);

    // ################
    // ##  modifier  ##
    // ################

    modifier groupIdTest(uint8 groupID) {
        require(groupID > 0 && groupID <= _groupsList, "group overflow");
        _;
    }

    modifier beDrager(uint8 dragerID) {
        require(isDrager[dragerID], "WRONG drager ID");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setTag(
        uint8 dragerID,
        uint8 triggerType,
        uint256 threshold,
        bool proRata
    ) external onlyAttorney groupIdTest(dragerID) {
        require(triggerType < 4, "触发类别错误");
        require(threshold < 5000 && threshold > 0, "实质性影响比例不正确");

        Tag storage tag = _tags[dragerID];
        isDrager[dragerID] = true;

        tag.triggerType = triggerType;
        tag.threshold = threshold;
        tag.proRata = proRata;

        emit SetTag(dragerID, triggerType, threshold, proRata);
    }

    function addFollower(uint8 dragerID, address follower)
        external
        onlyAttorney
        beDrager(dragerID)
    {
        _tags[dragerID].followers.addValue(follower);

        emit AddFollower(dragerID, follower);
    }

    function removeFollower(uint8 dragerID, address follower)
        external
        onlyAttorney
        beDrager(dragerID)
    {
        _tags[dragerID].followers.removeByValue(follower);

        emit RemoveFollower(dragerID, follower);
    }

    function delTag(uint8 dragerID) external onlyAttorney beDrager(dragerID) {
        delete _tags[dragerID];
        delete isDrager[dragerID];

        emit DelTag(dragerID);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function tagExist(address seller)
        external
        view
        onlyStakeholders
        returns (bool)
    {
        return isDrager[groupNumberOf[seller]];
    }

    function getTag(address seller)
        external
        view
        onlyStakeholders
        beDrager(groupNumberOf[seller])
        returns (
            address[] followers,
            uint8 triggerType,
            uint256 threshold,
            bool proRata
        )
    {
        followers = _tags[groupNumberOf[seller]].followers;
        triggerType = _tags[groupNumberOf[seller]].triggerType;
        threshold = _tags[groupNumberOf[seller]].threshold;
        proRata = _tags[groupNumberOf[seller]].proRata;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function _getDragerPosition(uint8 dragerID, uint256 parToSell)
        private
        view
        returns (bool biggest, uint256 shareRatio)
    {
        uint8 len = _groupsList.length;
        uint256[] memory parValue = new uint256[](len);
        uint8 i = 0;

        for (; i < len; i++) {
            for (uint8 j = 0; j < membersOfGroup[_groupsList[i]].length; j++) {
                (, uint256 par, ) = _bos.getMember(
                    membersOfGroup[_groupsList[i]][j]
                );
                parValue[i].add(par);
            }
        }

        shareRatio = parValue[dragerID].sub(parToSell).mul(10000).div(
            _bos.regCap()
        );

        biggest = true;

        if (shareRatio > 5000) {
            return (biggest, shareRatio);
        }

        i = 0;
        while (biggest && i < _groupsList.length) {
            if (parValue[i] > parValue[dragerID]) {
                biggest = false;
            }

            i++;
        }
        return (biggest, shareRatio);
    }

    function _isTriggered(address seller, uint256 parToSell)
        private
        view
        returns (bool)
    {
        uint8 dragerID = groupNumberOf[seller];

        if (!isDrager[dragerID]) return false;

        (bool biggest, uint256 shareRatio) = _getDragerPosition(
            dragerID,
            parToSell
        );

        Tag storage tag = _tags[dragerID];

        if (tag.triggerType == 1) {
            return !(shareRatio > 5000);
        } else if (tag.triggerType == 2) {
            return !(biggest && (shareRatio >= tag.threshold));
        } else if (tag.triggerType == 3) {
            return !biggest;
        }
    }

    function isTriggered(address ia) public view onlyBookeeper returns (bool) {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();

        uint8 len = dealsList.length;

        uint256 parToSell;
        uint256 parToBuy;

        for (uint8 i = 0; i < len; i++) {
            (uint8 typeOfDeal, , , address seller, address buyer) = IAgreement(
                ia
            ).parseSN(dealsList[i]);

            parToSell = 0;
            parToBuy = 0;

            if (
                typeOfDeal > 1 &&
                isDrager[groupNumberOf[seller]] &&
                groupNumberOf[seller] != groupNumberOf[buyer]
            ) {
                address[] memory members = membersOfGroup[
                    groupNumberOf[seller]
                ];
                for (uint8 j = 0; j < members.length; j++) {
                    parToSell += IAgreement(ia).parToSell(members[j]);
                    parToBuy += IAgreement(ia).parToBuy(members[j]);
                }
            }

            if (parToSell > parToBuy) {
                if (_tags[groupNumberOf[seller]].triggerType == 0) {
                    return true;
                }
                parToSell -= parToBuy;
                return _isTriggered(seller, parToSell);
            }
        }
        return false;
    }

    function _isExempted(address seller, address[] storage consentParties)
        private
        view
        returns (bool)
    {
        require(consentParties.length > 0, "consentParties is zero");

        uint8 dragerID = groupNumberOf[seller];

        if (!isDrager[dragerID]) return true;

        Tag storage tag = _tags[dragerID];

        for (uint8 i = 0; i < tag.followers.length; i++) {
            (bool exist, ) = consentParties.firstIndexOf(tag.followers[i]);
            if (!exist) {
                return false;
            }
        }

        return true;
    }

    function isExempted(address ia) public view onlyBookeeper returns (bool) {
        require(_bom.isPassed(ia), "决议没有通过");

        if (!isTriggered(ia)) return true;

        (address[] memory parties, ) = _bom.getYea(ia);
        address[] storage consentParties;
        for (uint256 j = 0; j < parties.length; j++)
            consentParties.push(parties[j]);

        bytes32[] memory dealsList = IAgreement(ia).dealsList();

        for (uint8 i = 0; i < dealsList.length; i++) {
            (uint8 typeOfDeal, , , address seller, ) = IAgreement(ia).parseSN(
                dealsList[i]
            );

            if (
                typeOfDeal > 1 &&
                isDrager[groupNumberOf[seller]] &&
                !_isExempted(seller, consentParties)
            ) return false;
        }

        return true;
    }
}
