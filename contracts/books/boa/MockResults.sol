// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IMockResults.sol";
import "../../common/lib/TopChain.sol";

import "./IInvestmentAgreement.sol";
import "../../common/lib/MembersRepo.sol";
import "../../common/lib/SNParser.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/SHASetting.sol";
import "../../common/ruting/IASetting.sol";

contract MockResults is IMockResults, IASetting, SHASetting, BOSSetting {
    using SNParser for bytes32;
    using TopChain for TopChain.Chain;
    using MembersRepo for MembersRepo.GeneralMeeting;

    MembersRepo.GeneralMeeting private _mgm;

    //#################
    //##  Write I/O  ##
    //#################

    function createMockGM() external onlyManager(0) {
        TopChain.Node[] memory snapshot = _bos.getSnapshot();
        
        _mgm.setMaxQtyOfMembers(0);
        _mgm.restoreChain(snapshot);
        _mockDealsOfIA();

        emit CreateMockGM(uint64(block.number));
    }

    function _mockDealsOfIA() private {
        bytes32[] memory dealsList = _ia.dealsList();

        uint256 len = dealsList.length;

        while (len > 0) {
            bytes32 sn = dealsList[len - 1];
            uint64 amount;

            if (_getSHA().basedOnPar())
                (, , amount,  , ) = _ia.getDeal(sn.sequence());
            else (, amount, , , ) = _ia.getDeal(sn.sequence());

            uint32 short = sn.ssnOfDeal();
            if (short > 0) mockDealOfSell(short, amount);

            mockDealOfBuy(sn, amount);

            len--;
        }
    }

    function mockDealOfSell(uint32 ssn, uint64 amount) public {
        (bytes32 shareNumber, , , , , ) = _bos.getShare(ssn);

        uint40 seller = shareNumber.shareholder();

        _mgm.chain.changeAmt(seller, amount, true);

        if (_mgm.chain.nodes[seller].amt == 0) {
            _mgm.delMember(seller);
        }

        emit MockDealOfSell(seller, amount);
    }

    function mockDealOfBuy(bytes32 sn, uint64 amount) public {
        uint40 buyer = sn.buyerOfDeal();

        if (!_mgm.isMember(buyer)) _mgm.addMember(buyer);

        // uint16 iBuyer = _mgm.indexOfMember(buyer);

        _mgm.chain.changeAmt(buyer, amount, false);

        uint16 group = sn.groupOfBuyer();
        if (group > 0) {
            _mgm.addMemberToGroup(buyer, group);
        }

        emit MockDealOfBuy(buyer, amount);
    }

    function addAlongDeal(
        bytes32 rule,
        bytes32 shareNumber,
        uint64 amount
    ) external onlyManager(0) {
        uint16 dGroup = _mgm.groupNo(rule.dragerOfLink());

        uint40 follower = shareNumber.shareholder();
        uint16 fGroup = _mgm.groupNo(follower);

        if (rule.proRataOfLink()) _proRataCheck(dGroup, fGroup, amount);

        // uint16 iFollower = _mgm.indexOfMember(follower);

        _mgm.chain.changeAmt(follower, amount, true);

        emit AddAlongDeal(follower, shareNumber, amount);
    }

    function _proRataCheck(
        uint16 dGroup,
        uint16 fGroup,
        uint64 amount
    ) private view{
        uint64 orgDGVotes = _bos.votesOfGroup(dGroup);
        uint64 curDGVotes = _mgm.votesOfGroup(dGroup);

        uint64 orgFGVotes = _bos.votesOfGroup(fGroup);
        uint64 curFGVotes = _mgm.votesOfGroup(fGroup);

        require(
            (orgDGVotes - curDGVotes) >=
                ((orgFGVotes - curFGVotes + amount) * orgDGVotes) / orgFGVotes,
            "MR.addAlongDeal: sell amount over flow"
        );
    }

    //##################
    //##    读接口    ##
    //##################

    function topGroup()
        public
        view
        returns (
            uint40 controllor,
            uint16 group,
            uint64 ratio
        )
    {
        controllor = _mgm.controllor();

        TopChain.Node storage c = _mgm.chain.nodes[controllor];

        group = c.group;

        ratio = (c.sum * 10000) / _mgm.chain.totalVotes();
    }

    function mockResults(uint40 acct)
        external
        view
        returns (
            uint40 top,
            uint16 group,
            uint64 sum
        )
    {
        // uint16 i = _mgm.indexOfMember(acct);

        // require(i > 0, "MR.mockResults: acct not exist");

        top = _mgm.chain.topOfBranch(acct);
        group = _mgm.chain.nodes[top].group;
        sum = _mgm.chain.nodes[top].sum;
    }
}
