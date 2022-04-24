/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../../common/config/BOSSetting.sol";
import "../../../common/config/DraftSetting.sol";
import "../../../common/lib/ArrayUtils.sol";

contract GroupsRepo is BOSSetting, DraftSetting {
    using ArrayUtils for address[];
    using ArrayUtils for uint8[];

    struct Group {
        mapping(address => bool) isGroupMember;
        address[] membersOfGroup;
    }

    // acct => group : 1 - 创始团队 ; 2... - 其他一致行动人集团或独立股东
    mapping(address => uint8) public groupNumberOf;

    // groupNo => Group
    mapping(uint8 => Group) internal _groups;

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

    modifier groupeExist(uint8 groupID) {
        require(isGroupNumber[groupID], "group NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function addMemberToGroup(uint8 groupID, address member)
        external
        onlyAttorney
    {
        require(
            groupID > 0 && groupID <= counterOfGroups + 1,
            "GroupID overflow"
        );
        require(groupNumberOf[member] == 0, "ALREADY GROUPED");

        Group storage group = _groups[groupID];

        group.isGroupMember = true;
        group.membersOfGroup.push(member);

        groupNumberOf[member] = groupID;

        if (groupID > counterOfGroups) {
            _groupsList.push(groupID);
            counterOfGroups = groupID;
            isGroupNumber[groupID] = true;
        }

        emit AddMemberToGroup(groupID, member);
    }

    function removeMemberFromGroup(uint8 groupID, address member)
        external
        onlyAttorney
        groupExist(groupID)
    {
        Group storage group = _groups[groupID];

        delete group.isGroupMember[member];
        group.membersOfGroup.removeByValue(member);

        delete groupNumberOf[member];

        if (group.membersOfGroup.length == 0) _delGroup(groupID);

        emit RemoveMemberFromGroup(groupID, member);
    }

    function _delGroup(uint8 groupID) private {
        delete _groups[groupID];

        _groupsList.removeByValue(groupID);

        delete isGroupNumber[groupID];

        emit DelGroup(groupID);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function groupsList() external view returns (uint8[]) {
        return _groupsList;
    }

    function groupWeight(uint8 groupID)
        public
        view
        returns (uint256 parValue, uint256 paidPar)
    {
        address[] memory members = _groups[groupID].membersOfGroup;
        uint256 len = members.length;

        for (uint256 i = 0; i < len; i++) {
            if (_bos.isMember(members[i])) {
                (, uint256 orgParValue, uint256 orgPaidPar) = _bos.getMember(
                    members[i]
                );
                
            }
        }
    }
}
