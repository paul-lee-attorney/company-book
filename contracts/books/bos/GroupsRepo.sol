/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "./SharesRepo.sol";

contract GroupsRepo is SharesRepo {
    using ArrayUtils for address[];
    using ArrayUtils for uint16[];
    using ShareSNParser for bytes32;

    mapping(uint16 => bool) public isGroup;

    mapping(uint16 => address[]) public membersOfGroup;

    mapping(address => uint16) public groupNo;

    uint16[] internal _groupsList;

    uint16 public controller;

    uint16 public counterOfGroups;

    //##################
    //##    Event    ##
    //##################
    event AddMemberToGroup(address acct, uint16 groupNo);
    event RemoveMemberFromGroup(address acct, uint16 groupNo);
    event SetController(uint16 groupNo);

    //##################
    //##    修饰器    ##s
    //##################

    modifier groupExist(uint16 group) {
        require(isGroup[group], "group is NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function addMemberToGroup(address acct, uint16 group) public onlyKeeper {
        require(group > 0, "ZERO group");
        require(group <= counterOfGroups + 1, "group OVER FLOW");
        require(groupNo[acct] == 0, "belongs to another group");

        if (!isGroup[group]) {
            isGroup[group] = true;
            _groupsList.push(group);
        }

        if (group > counterOfGroups) counterOfGroups = group;

        groupNo[acct] = group;
        membersOfGroup[group].push(acct);

        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(address acct, uint16 group)
        public
        groupExist(group)
        onlyKeeper
    {
        require(groupNo[acct] == group, "WRONG group number");

        membersOfGroup[group].removeByValue(acct);

        if (membersOfGroup[group].length == 0) {
            delete membersOfGroup[group];
            delete isGroup[group];
            _groupsList.removeByValue(group);
        }

        groupNo[acct] == 0;

        emit RemoveMemberFromGroup(acct, group);
    }

    function setController(uint16 group) external onlyKeeper groupExist(group) {
        controller = group;
        emit SetController(group);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function groupsList() external view returns (uint16[]) {
        return _groupsList;
    }
}
