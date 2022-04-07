/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

// import "../config/BOSSetting.sol";
// import "../config/BOMSetting.sol";
import "../config/DraftSetting.sol";

import "../lib/ArrayUtils.sol";
import "../lib/SafeMath.sol";

import "../interfaces/IAgreement.sol";

import "../interfaces/ISigPage.sol";

// import "../interfaces/IMotion.sol";

contract Groups is DraftSetting {
    using ArrayUtils for address[];
    // using SafeMath for uint256;
    using SafeMath for uint8;

    // acct => group : 1 - 创始团队 ; 2... - 其他一致行动人集团或独立股东
    mapping(address => uint8) public groupNumOf;

    // group => accts
    mapping(uint8 => address[]) public membersOfGroup;

    uint8 public counterOfGroups;

    uint8[] private _groupsList;

    // ################
    // ##   Event    ##
    // ################

    event AddMemberToGroup(uint8 indexed group, address member);

    event RemoveMemberFromGroup(uint8 indexed group, address member);

    event DelGroup(uint8 indexed group);

    // ################
    // ##  modifier  ##
    // ################

    modifier groupIdTest(uint8 group) {
        require(group > 0 && group <= counterOfGroups, "组编号 超限");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function addMemberToGroup(uint8 group, address member)
        external
        onlyAttorney
    {
        // require(ISigPage(getBookeeper()).isParty(member), "not Party to SHA");
        require(
            group > 0 && group <= counterOfGroups.add8(1),
            "group overflow"
        );
        require(
            groupNumOf[member] == group || groupNumOf[member] == 0,
            "member ALREADY GROUPED"
        );

        groupNumOf[member] = group;
        membersOfGroup[group].addValue(member);

        if (group > counterOfGroups) {
            groupsList.push(group);
            counterOfGroups = group;
        }

        emit AddMemberToGroup(group, member);
    }

    function removeMemberFromGroup(uint8 group, address member)
        external
        onlyAttorney
    {
        require(
            group > 0 && groupNumOf[member] == group,
            "INCORRECT group number"
        );

        delete groupNumOf[member];
        membersOfGroup[group].removeByValue(member);

        if (membersOfGroup[group].length == 0) _delGroup(group);

        emit RemoveMemberFromGroup(group, member);
    }

    function _delGroup(uint8 group) private onlyAttorney groupIdTest(group) {
        delete membersOfGroup[group];

        groupsList.removeByValue(group);

        emit DelGroup(group);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function groupsList() external view returns (uint8[]) {
        return _groupsList;
    }
}
