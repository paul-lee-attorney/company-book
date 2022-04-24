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

    mapping(address => bytes32[]) public sharesInHand;

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

    function _addShareToMember(bytes6 ssn, address acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        sharesInHand[acct].push(_shares[ssn].sn);
    }

    function _removeShareFromMember(bytes6 ssn, address acct)
        internal
        shareExist(ssn)
        memberExist(acct)
    {
        sharesInHand[acct].removeByValue(_shares[ssn].sn);
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

    function parInHand(address acct)
        external
        view
        memberExist(acct)
        returns (uint256 parValue)
    {
        uint256 len = sharesInHand[acct].length;
        for (uint256 i = 0; i < len; i++)
            parValue += _shares[sharesInHand[acct][i].short()].parValue;
    }

    function paidInHand(address acct)
        external
        view
        memberExist(acct)
        returns (uint256 paidPar)
    {
        uint256 len = sharesInHand[acct].length;
        for (uint256 i = 0; i < len; i++)
            paidPar += _shares[sharesInHand[acct][i].short()].paidPar;
    }
}
