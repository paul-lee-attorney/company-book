/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All rights reserved.
 * */

pragma solidity ^0.4.24;

// import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "../../common/config/BOSSetting.sol";

contract BOSCalculator is BOSSetting {
    // using ArrayUtils for address[];
    using ShareSNParser for bytes32;

    //##################
    //##   查询接口   ##
    //##################

    function membersOfClass(uint8 class) external view returns (address[]) {
        require(class < _bos.counterOfClasses(), "class over flow");

        bytes32[] memory list = _bos.snList();

        uint256 len = list.length;
        address[] storage members;

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

    function parInHand(address acct)
        public
        view
        memberExist(acct)
        returns (uint256 parValue)
    {
        bytes32[] memory list = _bos.sharesInHand(acct);
        uint256 len = list.length;
        for (uint256 i = 0; i < len; i++) {
            (, uint256 par, , , , , ) = _bos.getShare(list[i].short());
            parValue += par;
        }
    }

    function paidInHand(address acct)
        public
        view
        memberExist(acct)
        returns (uint256 paidPar)
    {
        bytes32[] memory list = _bos.sharesInHand(acct);

        uint256 len = list.length;
        for (uint256 i = 0; i < len; i++) {
            (, , uint256 paid, , , , ) = _bos.getShare(list[i].short());
            paidPar += paid;
        }
    }

    function parOfGroup(uint16 group) public view returns (uint256 parValue) {
        require(_bos.isGroup(group), "GROUP not exist");

        address[] memory members = _bos.membersOfGroup(group);

        uint256 len = members.length;

        for (uint256 i = 0; i < len; i++) parValue += parInHand(members[i]);
    }

    function paidOfGroup(uint16 group) public view returns (uint256 paidPar) {
        require(_bos.isGroup(group), "GROUP not exist");

        address[] memory members = _bos.membersOfGroup(group);

        uint256 len = members.length;

        for (uint256 i = 0; i < len; i++) paidPar += paidInHand(members[i]);
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
