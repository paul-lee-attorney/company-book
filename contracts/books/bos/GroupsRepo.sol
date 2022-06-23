/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "./SharesRepo.sol";

contract GroupsRepo is SharesRepo {
    // using ArrayUtils for uint16[];
    // using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // mapping(uint16 => bool) public isGroup;

    mapping(uint16 => EnumerableSet.UintSet) private _membersOfGroup;

    mapping(uint40 => uint16) internal _groupNo;

    // uint16[] internal _groupsList;

    EnumerableSet.UintSet private _groupsList;

    uint16 public controller;

    uint16 public counterOfGroups;

    //#################
    //##    Event    ##
    //#################
    event AddMemberToGroup(uint40 acct, uint16 groupNo);
    event RemoveMemberFromGroup(uint40 acct, uint16 groupNo);
    event SetController(uint16 groupNo);

    //##################
    //##    修饰器    ##s
    //##################

    modifier groupExist(uint16 group) {
        require(_groupsList.contains(uint256(group)), "group is NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function addMemberToGroup(uint40 acct, uint16 group) public onlyKeeper {
        require(group > 0, "ZERO group");
        require(group <= counterOfGroups + 1, "group OVER FLOW");
        require(_groupNo[acct] == 0, "belongs to another group");

        _groupsList.add(uint256(group));

        // if (!isGroup[group]) {
        //     isGroup[group] = true;
        //     _groupsList.push(group);
        // }

        if (group > counterOfGroups) counterOfGroups = group;

        _groupNo[acct] = group;

        _membersOfGroup[group].add(uint256(acct));

        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(uint40 acct, uint16 group)
        public
        groupExist(group)
        onlyKeeper
    {
        require(_groupNo[acct] == group, "WRONG group number");

        _membersOfGroup[group].remove(uint256(acct));

        if (_membersOfGroup[group].length() == 0) {
            delete _membersOfGroup[group];
            // delete isGroup[group];
            // _groupsList.removeByValue(group);

            _groupsList.remove(uint256(group));
        }

        _groupNo[acct] == 0;

        emit RemoveMemberFromGroup(acct, group);
    }

    function setController(uint16 group) external onlyKeeper groupExist(group) {
        controller = group;
        emit SetController(group);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function groupNo(uint40 acct) external view onlyUser returns (uint16) {
        return _groupNo[acct];
    }

    function membersOfGroup(uint16 group)
        external
        view
        onlyUser
        returns (uint40[])
    {
        return _membersOfGroup[group].valuesToUint40();
    }

    function isGroup(uint16 group) external view onlyUser returns (bool) {
        return _groupsList.contains(uint256(group));
    }

    function groupsList() external view onlyUser returns (uint16[]) {
        return _groupsList.valuesToUint16();
    }
}
