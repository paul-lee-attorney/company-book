/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./ArrayUtils.sol";
import "./UserGroup.sol";

library SigList {
    using ArrayUtils for uint32[];
    using UserGroup for UserGroup.Group;

    struct List {
        mapping(uint32 => uint32) signingDate;
        UserGroup.Group sigParties;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function addSignature(
        List storage list,
        uint32 party,
        uint32 sigDate
    ) internal returns (bool flag) {
        if (list.sigParties.addMember(party)) {
            list.signingDate[party] = sigDate;
            flag = true;
        }
    }

    function removeSignature(List storage list, uint32 party)
        internal
        returns (bool flag)
    {
        if (list.sigParties.removeMember(party)) {
            list.signingDate[party] = 0;
            flag = true;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isSigner(List storage list, uint32 acct)
        internal
        view
        returns (bool)
    {
        return list.sigParties.isMember(acct);
    }

    function sigDate(List storage list, uint32 acct)
        internal
        view
        returns (uint32)
    {
        require(isSigner(list, acct), "not a party");

        return list.signingDate[acct];
    }

    function qtyOfSigners(List storage list) internal view returns (uint256) {
        return list.sigParties.qtyOfMembers();
    }

    function signers(List storage list) internal view returns (uint32[]) {
        return list.sigParties.getMembers();
    }
}
