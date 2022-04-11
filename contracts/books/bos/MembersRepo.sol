/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";

import "./SharesRepo.sol";

contract MembersRepo is SharesRepo {
    using ArrayUtils for address[];
    using ShareSNParser for bytes32;

    mapping(address => bool) public isMember;

    // 股东名册
    address[] private _membersList;

    uint8 public maxQtyOfMembers;

    //##################
    //##    Event    ##
    //##################

    event SetMaxQtyOfMembers(uint8 max);
    event AddMember(address indexed acct, uint256 qtyOfMembers);
    event RemoveMember(address indexed acct, uint256 qtyOfMembers);

    //##################
    //##    修饰器    ##s
    //##################

    modifier onlyMember() {
        require(isMember[msg.sender], "NOT Member");
        _;
    }

    modifier memberExist(address acct) {
        require(isMember[acct], "Acct is NOT Member");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    constructor(uint8 max) public {
        maxQtyOfMembers = max;
    }

    function setMaxQtyOfMembers(uint8 max) external onlyAdmin {
        maxQtyOfMembers = max;
        emit SetMaxQtyOfMembers(max);
    }

    function _addMember(address acct) internal {
        (bool exist, ) = _membersList.firstIndexOf(acct);

        if (!exist) {
            require(
                _membersList.length < maxQtyOfMembers,
                "Qty of Members overflow"
            );

            _membersList.push(acct);
            isMember[acct] = true;

            emit AddMember(acct, _membersList.length);
        }
    }

    function _removeMember(address acct) internal {
        _membersList.removeByValue(acct);
        isMember[acct] = false;

        emit RemoveMember(acct, _membersList.length);
    }

    function _updateMembersList(address acct) internal {
        uint256 len = _snList.length;
        bool flag;

        for (uint256 i = 0; i < len; i++) {
            if (acct == _snList[i].shareholder()) {
                flag = true;
                break;
            }
        }

        if (!flag) _removeMember(acct);
    }

    //##################
    //##   查询接口   ##
    //##################

    function membersList() external view returns (address[]) {
        return _membersList;
    }

    function getMember(address acct)
        public
        view
        memberExist(acct)
        returns (
            bytes32[] sharesInHand,
            uint256 parValue,
            uint256 paidPar
        )
    {
        bytes32[] storage sharesList;
        uint256 len = _snList.length;

        for (uint256 i = 0; i < len; i++) {
            if (_snList[i].shareholder() == acct) {
                sharesList.push(_snList[i]);
                (uint256 par, uint256 paid, , , , ) = getShare(_snList[i]);
                parValue += par;
                paidPar += paid;
            }
        }

        sharesInHand = sharesList;
    }
}
