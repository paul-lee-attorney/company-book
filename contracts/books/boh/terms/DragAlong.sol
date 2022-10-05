/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/IInvestmentAgreement.sol";
import "../../boa/IMockResults.sol";

import "../../../common/components/IDocumentsRepo.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOASetting.sol";

import "../../../common/lib/SNParser.sol";
import "../../../common/lib/SNFactory.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/EnumsRepo.sol";

import "./IAlongs.sol";

contract DragAlong is IAlongs, BOSSetting, BOASetting {
    using SNParser for bytes32;
    using SNFactory for bytes;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Link {
        EnumerableSet.UintSet followers;
        bytes32 rule;
    }

    // struct linkRule {
    //     uint40 drager;
    //     uint16 group;
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

    // rep => Link
    mapping(uint256 => Link) internal _links;

    // drager => rep
    mapping(uint256 => uint256) internal _reps;

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerExist(uint40 drager) {
        require(_dragers.contains(drager), "WRONG drager ID");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function _createLinkRule(
        uint40 drager,
        uint16 group,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.acctToSN(0, drager);
        _sn = _sn.sequenceToSN(5, group);
        _sn[7] = bytes1(triggerType);
        _sn = _sn.dateToSN(8, threshold);
        _sn[12] = (proRata) ? 1 : 0;
        _sn = _sn.dateToSN(13, unitPrice);
        _sn = _sn.dateToSN(17, roe);

        return _sn.bytesToBytes32();
    }

    function createLink(
        uint40 drager,
        uint8 triggerType,
        uint32 threshold,
        bool proRata,
        uint32 unitPrice,
        uint32 roe
    ) external onlyAttorney {
        require(triggerType < 4, "WRONG trigger type");
        require(threshold <= 5000, "WRONG ratio of threshold");

        require(
            _links[_reps[drager]].rule == bytes32(0),
            "DA.createLink: tag rule ALREADY EXIST"
        );

        uint16 group = _bos.groupNo(drager);

        if (group == 0) {
            dragers.add(drager);
            _reps[drager] = drager;
        } else {
            _addGroupMemberAsDrager(group, drager);
        }

        bytes32 rule = _createLinkRule(
            drager,
            group,
            triggerType,
            threshold,
            proRata,
            unitPrice,
            roe
        );

        _links[drager].rule = rule;

        emit SetLink(drager, rule);
    }

    function _addGroupMemberAsDrager(uint16 group, uint40 drager) private {
        uint40[] memory members = _bos.membersOfGroup(group);
        uint256 len = members.length;

        while (len > 0) {
            _dragers.add(members[len - 1]);
            _reps[members[len - 1]] = drager;
            len--;
        }
    }

    function addFollower(uint40 drager, uint40 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        if (_links[_reps[drager]].followers.add(follower))
            emit AddFollower(drager, follower);
    }

    function removeFollower(uint40 drager, uint40 follower)
        external
        onlyAttorney
        dragerExist(drager)
    {
        if (_links[drager].followers.remove(follower))
            emit RemoveFollower(drager, follower);
    }

    function delLink(uint40 drager) external onlyAttorney dragerExist(drager) {
        delete _links[drager];

        uint16 group = _bos.groupNo(drager);
        if (group > 0) {
            uint40[] memory members = _bos.membersOfGroup(group);
            uint256 len = members.length;

            while (len > 0) {
                _dragers.remove(members[len - 1]);
                delete _reps[members[len - 1]];
                len--;
            }
        } else _dragers.remove(drager);

        emit DelLink(drager);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint40 drager)
        external
        view
        dragerExist(drager)
        returns (bytes32)
    {
        return _links[drager].rule;
    }

    function isDrager(uint40 drager) external view returns (bool) {
        return _dragers.contains(drager);
    }
    
    function repOf(uint40 drager) external dragerExist(drager) view returns(uint40) {
        return _reps[drager];
    }

    function isLinked(uint40 drager, uint40 follower)
        public
        view
        dragerExist(drager)
        returns (bool)
    {
        return _links[_reps[drager]].followers.contains(follower);
    }

    function dragers() external view returns (uint40[]) {
        return _dragers.valuesToUint40();
    }

    function followers(uint40 drager)
        external
        view
        dragerExist(drager)
        returns (uint40[])
    {
        return _links[_reps[drager]].followers.valuesToUint40();
    }

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view onlyKeeper returns (bool) {
        require(isTriggered(ia, sn), "not triggered");

        uint40 drager = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequence())
            .shareholder();

        require(caller == drager, "DA.priceCheck: caller is not drager of DragAlong");

        require(
            isLinked(caller, shareNumber.shareholder()),
            "DA.PriceCheck: caller and target shareholder NOT linked"
        );

        uint32 dealPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequence()
        );

        bytes32 rule = _links[_reps[caller]].rule;

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
            _boa.currentState(ia) !=
            uint8(EnumsRepo.BODStates.Circulated)
        ) return false;

        if (
            sn.typeOfDeal() == uint8(EnumsRepo.TypeOfDeal.CapitalIncrease) ||
            sn.typeOfDeal() == uint8(EnumsRepo.TypeOfDeal.PreEmptive)
        ) return false;

        uint40 seller = IInvestmentAgreement(ia)
            .shareNumberOfDeal(sn.sequence())
            .shareholder();

        if (!_dragers.contains(seller)) return false;

        bytes32 rule = _links[_reps[seller]].rule;

        if (
            rule.triggerTypeOfLink() ==
            uint8(EnumsRepo.TriggerTypeOfAlongs.NoConditions)
        ) return true;

        uint40 controllor = _bos.controller();
        uint16 conGroup = _bos.groupNo(controllor);

        if ((controllor != seller) && (conGroup == 0 || conGroup != _bos.groupNo(seller))) return false;

        (uint40 newControllor, uint16 newConGroup, uint64 ratio) = IMockResults(
            _boa.mockResultsOfIA(ia)
        ).topGroup();

        if ((controllor != newControllor) && (conGroup == 0 || conGroup != newConGroup)) return true;

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
