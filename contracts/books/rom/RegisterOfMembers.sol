// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";

import "../../common/lib/MembersRepo.sol";
import "../../common/lib/TopChain.sol";

import "../../common/ruting/BOSSetting.sol";

contract RegisterOfMembers is IRegisterOfMembers, BOSSetting {
    using MembersRepo for MembersRepo.GeneralMeeting;

    MembersRepo.GeneralMeeting private _gm;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyBOS() {
        require(
            msg.sender == address(_bos),
            "ROM.onlyBOS: msgSender is not bos"
        );
        _;
    }

    modifier memberExist(uint40 acct) {
        require(isMember(acct), "ROM.memberExist: NOT Member");
        _;
    }

    modifier groupExist(uint16 group) {
        require(isGroup(group), "ROM.groupExist: NOT group");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setVoteBase(bool onPar) external onlyKeeper {
        if (_gm.setVoteBase(onPar)) emit SetVoteBase(onPar);
    }

    function capIncrease(uint64 paid, uint64 par) external onlyBOS {
        uint64 blocknumber = _gm.changeAmtOfCap(paid, par, false);
        emit CapIncrease(paid, par, blocknumber);
    }

    function capDecrease(uint64 paid, uint64 par) external onlyBOS {
        uint64 blocknumber = _gm.changeAmtOfCap(paid, par, true);
        emit CapDecrease(paid, par, blocknumber);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyManager(1) {
        _gm.setMaxQtyOfMembers(max);
        emit SetMaxQtyOfMembers(max);
    }

    function setAmtBase(bool onPar) external onlyKeeper {
        if (_gm.setAmtBase(onPar)) emit SetAmtBase(onPar);
    }

    function addMember(uint40 acct) external onlyBOS {
        require(
            _gm.qtyOfMembers() < _gm.maxQtyOfMembers() ||
                _gm.maxQtyOfMembers() == 0,
            "Qty of Members overflow"
        );

        if (_gm.addMember(acct)) emit AddMember(acct, _gm.qtyOfMembers());
    }

    function addShareToMember(uint32 ssn, uint40 acct) external onlyBOS {
        (bytes32 shareNumber, uint64 paid, uint64 par, , ) = _bos.getShare(ssn);

        if (_gm.addShareToMember(shareNumber, acct)) {
            _gm.changeAmtOfMember(acct, paid, par, false);
            emit AddShareToMember(shareNumber, acct);
        }
    }

    function removeShareFromMember(uint32 ssn, uint40 acct) external onlyBOS {
        (bytes32 shareNumber, uint64 paid, uint64 par, , ) = _bos.getShare(ssn);

        changeAmtOfMember(acct, paid, par, true);

        if (_gm.removeShareFromMember(shareNumber, acct)) {
            if (_gm.qtyOfSharesInHand(acct) == 0) _gm.delMember(acct);

            emit RemoveShareFromMember(shareNumber, acct);
        }
    }

    function changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) public onlyBOS {
        if (decrease) {
            require(
                _gm.paidOfMember(acct) > deltaPaid,
                "BOS._changeAmtOfMember: paid amount not enough"
            );
            require(
                _gm.parOfMember(acct) > deltaPar,
                "BOS._changeAmtOfMember: par amount not enough"
            );
        }

        uint64 blocknumber = _gm.changeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            decrease
        );

        emit ChangeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            decrease,
            blocknumber
        );
    }

    function addMemberToGroup(uint40 acct, uint16 group) external onlyKeeper {
        require(
            _gm.groupNo(acct) == 0,
            "BOS.addMemberToGroup: remove acct from group first"
        );

        _gm.removeMemberFromChain(acct);
        _gm.addMemberToGroup(acct, group);

        emit AddMemberToGroup(acct, group);
    }

    function removeMemberFromGroup(uint40 acct, uint16 group)
        external
        onlyKeeper
    {
        require(
            group == _gm.groupNo(acct),
            "BOS.removeMemberFromGroup: Acct is not member of Group"
        );
        _gm.removeMemberFromGroup(acct);
        emit RemoveMemberFromGroup(acct, group);
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    function basedOnPar() external view returns (bool) {
        return _gm.basedOnPar();
    }

    function maxQtyOfMembers() external view returns (uint16) {
        return _gm.maxQtyOfMembers();
    }

    function paidCap() external view returns (uint64) {
        return _gm.paidCap();
    }

    function parCap() external view returns (uint64) {
        return _gm.parCap();
    }

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64 paid, uint64 par)
    {
        return _gm.capAtBlock(blocknumber);
    }

    function totalVotes() external view returns (uint64) {
        return _gm.totalVotes();
    }

    function sharesList() external view returns (bytes32[] memory) {
        return _gm.sharesList();
    }

    function sharenumberExist(bytes32 sharenumber)
        external
        view
        returns (bool)
    {
        return _gm.shareNumberExist(sharenumber);
    }

    function isMember(uint40 acct) public view returns (bool) {
        return _gm.isMember(acct);
    }

    function paidOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 paid)
    {
        paid = _gm.paidOfMember(acct);
    }

    function parOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 par)
    {
        par = _gm.parOfMember(acct);
    }

    function votesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64)
    {
        return _gm.votesInHand(acct);
    }

    function votesAtBlock(uint40 acct, uint64 blocknumber)
        external
        view
        returns (uint64)
    {
        return _gm.votesAtBlock(acct, blocknumber, _gm.basedOnPar());
    }

    function sharesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (bytes32[] memory)
    {
        return _gm.sharesInHand(acct);
    }

    function groupNo(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint16)
    {
        return _gm.groupNo(acct);
    }

    function qtyOfMembers() external view returns (uint16) {
        return _gm.qtyOfMembers();
    }

    function membersList() external view returns (uint40[] memory) {
        return _gm.membersList();
    }

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        memberExist(acct1)
        memberExist(acct2)
        returns (bool)
    {
        return _gm.affiliated(acct1, acct2);
    }

    // ==== group ====

    function isGroup(uint16 group) public view returns (bool) {
        return _gm.isGroup(group);
    }

    function counterOfGroups() external view returns (uint16) {
        return _gm.counterOfGroups();
    }

    function qtyOfGroups() external view returns (uint64) {
        return _gm.qtyOfGroups();
    }

    function controllor() external view returns (uint40) {
        return _gm.controllor();
    }

    function votesOfController() external view returns (uint64) {
        return _gm.votesOfHead();
    }

    function votesOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint64)
    {
        return _gm.votesOfGroup(group);
    }

    function leaderOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint64)
    {
        return _gm.leaderOfGroup(group);
    }

    function membersOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint40[] memory)
    {
        return _gm.membersOfGroup(group);
    }

    function deepOfGroup(uint16 group)
        external
        view
        groupExist(group)
        returns (uint16)
    {
        return _gm.deepOfGroup(group);
    }

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _gm.getSnapshot();
    }
}
