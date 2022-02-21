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

// import "../interfaces/IMotion.sol";

contract TagAlong is BOSSetting, BOMSetting, DraftSetting {
    using ArrayUtils for address[];
    using SafeMath for uint256;
    using SafeMath for uint8;

    // acct => groupID : 1 - 创始团队 ; 2... - 其他一致行动人集团或独立股东
    mapping(address => uint8) private _groupNumOf;

    // groupID => accts
    mapping(uint8 => address[]) private _membersOfGroup;

    uint8 private _qtyOfGroups;

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
    mapping(uint8 => bool) private _isDrager;

    // ################
    // ##   Event    ##
    // ################

    event AddMemberToGroup(uint8 indexed groupID, address member);

    event RemoveMemberFromGroup(uint8 indexed groupID, address member);

    event DelGroup(uint8 indexed groupID);

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
        require(groupID > 0 && groupID <= _qtyOfGroups, "组编号 超限");
        _;
    }

    modifier beDrager(uint8 dragerID) {
        require(_isDrager[dragerID], "Tag编号 错误");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function addMemberToGroup(uint8 groupID, address member)
        external
        onlyAttorney
    // isMemberOrInvestor(member)
    {
        require(ISigPage(getBookeeper()).isParty(member), "not Party to SHA");
        require(
            groupID > 0 && groupID <= _qtyOfGroups.add8(1),
            "groupID overflow"
        );
        require(
            _groupNumOf[member] == groupID || _groupNumOf[member] == 0,
            "reinput member"
        );

        _groupNumOf[member] = groupID;
        _membersOfGroup[groupID].addValue(member);

        if (groupID > _qtyOfGroups) _qtyOfGroups = groupID;

        emit AddMemberToGroup(groupID, member);
    }

    function removeMemberFromGroup(uint8 groupID, address member)
        external
        onlyAttorney
    {
        require(groupID > 0 && _groupNumOf[member] == groupID, "组编号 错误");

        delete _groupNumOf[member];
        _membersOfGroup[groupID].removeByValue(member);

        if (_membersOfGroup[groupID].length == 0) delGroup(groupID);

        emit RemoveMemberFromGroup(groupID, member);
    }

    function delGroup(uint8 groupID) public onlyAttorney groupIdTest(groupID) {
        for (uint8 i = groupID; i < _qtyOfGroups; i++) {
            for (uint8 j = 0; j < _membersOfGroup[i + 1].length; j++) {
                _groupNumOf[_membersOfGroup[i + 1][j]] = i;
            }

            _membersOfGroup[i] = _membersOfGroup[i + 1];
        }

        delete _membersOfGroup[_qtyOfGroups];
        _qtyOfGroups--;

        emit DelGroup(groupID);
    }

    function setTag(
        uint8 dragerID,
        uint8 triggerType,
        uint256 threshold,
        bool proRata
    ) external onlyAttorney groupIdTest(dragerID) {
        require(triggerType < 4, "触发类别错误");
        require((threshold < 5000) && (threshold > 0), "实质性影响比例不正确");

        Tag storage tag = _tags[dragerID];
        _isDrager[dragerID] = true;

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
        _isDrager[dragerID] = false;

        emit DelTag(dragerID);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getQtyOfGroups() external view onlyStakeholders returns (uint8) {
        return _qtyOfGroups;
    }

    function getGroupNumOf(address seller)
        external
        view
        onlyStakeholders
        returns (uint8)
    {
        return _groupNumOf[seller];
    }

    function getMembersOfGroup(uint8 groupID)
        external
        view
        onlyStakeholders
        returns (address[])
    {
        return _membersOfGroup[groupID];
    }

    function tagExist(address seller)
        external
        view
        onlyStakeholders
        returns (bool)
    {
        return _isDrager[_groupNumOf[seller]];
    }

    function getTag(address seller)
        external
        view
        onlyStakeholders
        beDrager(_groupNumOf[seller])
        returns (
            address[] followers,
            uint8 triggerType,
            uint256 threshold,
            bool proRata
        )
    {
        // require (_isDrager[_groupNumOf[seller]], "跟随安排 不存在!");
        followers = _tags[_groupNumOf[seller]].followers;
        triggerType = _tags[_groupNumOf[seller]].triggerType;
        threshold = _tags[_groupNumOf[seller]].threshold;
        proRata = _tags[_groupNumOf[seller]].proRata;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function _getDragerPosition(uint8 dragerID, uint256 parToSell)
        private
        view
        returns (bool biggest, uint256 shareRatio)
    {
        uint256[] memory parValue = new uint256[](_qtyOfGroups);
        uint8 i = 1;

        for (; i <= _qtyOfGroups; i++) {
            for (uint8 j = 0; j < _membersOfGroup[i].length; j++) {
                (, uint256 par, ) = _bos.getMember(_membersOfGroup[i][j]);
                parValue[i - 1].add(par);
            }
        }

        shareRatio = parValue[dragerID - 1].sub(parToSell).mul(10000).div(
            _bos.regCap()
        );

        biggest = true;

        if (shareRatio > 5000) {
            return (biggest, shareRatio);
        }

        i = 1;
        while (biggest && i < _qtyOfGroups) {
            if (parValue[i] > parValue[dragerID - 1]) {
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
        uint8 dragerID = _groupNumOf[seller];

        if (!_isDrager[dragerID]) return false;

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
        IAgreement _ia = IAgreement(ia);

        uint8 qtyOfDeals = _ia.getQtyOfDeals();

        uint256 parToSell;
        uint256 parToBuy;

        for (uint8 i = 0; i < qtyOfDeals; i++) {
            (
                ,
                ,
                address seller,
                address buyer,
                ,
                ,
                ,
                ,
                uint8 typeOfDeal,
                ,

            ) = _ia.getDeal(i);

            parToSell = 0;
            parToBuy = 0;

            if (
                typeOfDeal > 1 &&
                _isDrager[_groupNumOf[seller]] &&
                _groupNumOf[seller] != _groupNumOf[buyer]
            ) {
                address[] memory members = _membersOfGroup[_groupNumOf[seller]];
                for (uint8 j = 0; j < members.length; j++) {
                    parToSell += _ia.getParToSell(members[j]);
                    parToBuy += _ia.getParToBuy(members[j]);
                }
            }

            if (parToSell > parToBuy) {
                if (_tags[_groupNumOf[seller]].triggerType == 0) {
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

        uint8 dragerID = _groupNumOf[seller];

        if (!_isDrager[dragerID]) return true;

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

        uint8 qtyOfDeals = IAgreement(ia).getQtyOfDeals();

        for (uint8 i = 0; i < qtyOfDeals; i++) {
            (, , address seller, , , , , , uint8 typeOfDeal, , ) = IAgreement(
                ia
            ).getDeal(i);

            if (
                typeOfDeal > 1 &&
                _isDrager[_groupNumOf[seller]] &&
                !_isExempted(seller, consentParties)
            ) return false;
        }

        return true;
    }
}
