/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/SNParser.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/access/AccessControl.sol";

import "./IBOSCalculator.sol";

contract BOSCalculator is
    IBOSCalculator,
    IBookSetting,
    BOSSetting,
    AccessControl
{
    using SNParser for bytes32;

    //##################
    //##   查询接口   ##
    //##################

    function setBooks(address[8] books) external onlyDirectKeeper {
        _setBOS(books[uint8(EnumsRepo.NameOfBook.BOS)]);
    }

    function membersOfClass(uint8 class) external view returns (uint40[]) {
        require(class < _bos.counterOfClasses(), "class over flow");

        bytes32[] memory list = _bos.snList();

        uint256 len = list.length;
        uint40[] storage members;

        for (uint256 i = 0; i < len; i++)
            if (list[i].class() == class) members.push(list[i].shareholder());

        return members;
    }

    function sharesOfClass(uint8 class) external view returns (bytes32[]) {
        require(class < _bos.counterOfClasses(), "class over flow");

        bytes32[] memory list = _bos.snList();

        uint256 len = list.length;
        bytes32[] storage shares;

        for (uint256 i = 0; i < len; i++)
            if (list[i].class() == class) shares.push(list[i]);

        return shares;
    }

    function parOfGroup(uint16 group) public view returns (uint64 parValue) {
        require(_bos.isGroup(group), "GROUP not exist");

        uint40[] memory members = _bos.membersOfGroup(group);

        uint256 len = members.length;

        for (uint256 i = 0; i < len; i++)
            parValue += _bos.parInHand(members[i]);
    }

    function paidOfGroup(uint16 group) public view returns (uint64 paidPar) {
        require(_bos.isGroup(group), "GROUP not exist");

        uint40[] memory members = _bos.membersOfGroup(group);

        uint256 len = members.length;

        for (uint256 i = 0; i < len; i++)
            paidPar += _bos.paidInHand(members[i]);
    }

    function updateController(bool basedOnPar) external onlyKeeper {
        uint16[] memory groups = _bos.groupsList();

        uint256 len = groups.length;

        uint16 index;

        for (uint16 i = 0; i < len; i++) {
            if (basedOnPar) {
                if (parOfGroup(groups[i]) > parOfGroup(index)) index = i;
            } else if (paidOfGroup(groups[i]) > paidOfGroup(index)) index = i;
        }

        _bos.setController(index);
    }
}
