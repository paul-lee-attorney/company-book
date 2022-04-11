/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/config/DraftSetting.sol";
import "../../common/lib/ArrayUtils.sol";

contract Groups is DraftSetting {
    using ArrayUtils for address[];
    using ArrayUtils for uint8[];

    // acct => group : 1 - 创始团队 ; 2... - 其他一致行动人集团或独立股东
    mapping(address => uint8) public groupNumberOf;

    // group => accts
    mapping(uint8 => address[]) public membersOfGroup;

    mapping(uint8 => bool) public isGroupNumber;

    uint8 public counterOfGroups;

    uint8[] internal _groupsList;

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
        require(group > 0 && group <= counterOfGroups + 1, "group overflow");
        require(
            groupNumberOf[member] == group || groupNumberOf[member] == 0,
            "ALREADY GROUPED"
        );

        groupNumberOf[member] = group;
        membersOfGroup[group].addValue(member);

        if (group > counterOfGroups) {
            _groupsList.push(group);
            counterOfGroups = group;
            isGroupNumber[group] = true;
        }

        emit AddMemberToGroup(group, member);
    }

    function removeMemberFromGroup(uint8 group, address member)
        external
        onlyAttorney
    {
        require(
            group > 0 && groupNumberOf[member] == group,
            "INCORRECT group number"
        );

        delete groupNumberOf[member];
        membersOfGroup[group].removeByValue(member);

        if (membersOfGroup[group].length == 0) _delGroup(group);

        emit RemoveMemberFromGroup(group, member);
    }

    function _delGroup(uint8 group) private groupIdTest(group) {
        delete membersOfGroup[group];

        _groupsList.removeByValue(group);

        isGroupNumber[group] = false;

        emit DelGroup(group);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function groupsList() external view returns (uint8[]) {
        return _groupsList;
    }
}
