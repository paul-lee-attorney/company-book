// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/lib/MotionsRepo.sol";
import "../common/lib/TopChain.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOPSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/ruting/ROMSetting.sol";

contract QueryWindow is
    BOASetting,
    BODSetting,
    BOMSetting,
    BOOSetting,
    BOPSetting,
    BOSSetting,
    SHASetting,
    ROMSetting
{
    function isBooked(address caller) external view returns (bool flag) {
        if (
            caller == address(_boa) ||
            caller == address(_bod) ||
            caller == address(_boh) ||
            caller == address(_bom) ||
            caller == address(_boo) ||
            caller == address(_bop) ||
            caller == address(_bos) ||
            caller == address(_rom)
        ) flag = true;
    }

    //###############
    //##    BOA    ##
    //###############

    function typeOfIA(address ia) external view returns (uint8) {
        return _boa.typeOfIA(ia);
    }

    function frDealsOfIA(address ia) external view returns (address) {
        return _boa.frDealsOfIA(ia);
    }

    function mockResultsOfIA(address ia) external view returns (address) {
        return _boa.mockResultsOfIA(ia);
    }

    function templateOfBOA(uint8 typeOfDoc) external view returns (address) {
        return _boa.template(typeOfDoc);
    }

    function iaExist(address body) external view returns (bool) {
        return _boa.isRegistered(body);
    }

    function counterOfBOA() external view returns (uint32) {
        return _boa.counterOfDocs();
    }

    function iaPassedReview(address body) external view returns (bool) {
        return _boa.passedReview(body);
    }

    function iaIsCirculated(address body) external view returns (bool) {
        return _boa.isCirculated(body);
    }

    function qtyOfIAs() external view returns (uint256) {
        return _boa.qtyOfDocs();
    }

    function iasList() external view returns (bytes32[] memory) {
        return _boa.docsList();
    }

    function getIA(address body)
        external
        view
        returns (bytes32 sn, bytes32 docHash)
    {
        return _boa.getDoc(body);
    }

    function stateOfIA(address body) external view returns (uint8) {
        return _boa.currentState(body);
    }

    function reviewDeadlineBNOfIA(address body) external view returns (uint32) {
        return _boa.reviewDeadlineBNOf(body);
    }

    function votingDeadlineBNOfIA(address body) external view returns (uint32) {
        return _boa.votingDeadlineBNOf(body);
    }

    //###############
    //##    BOD    ##
    //###############

    function maxQtyOfDirectors() external view returns (uint8) {
        return _bod.maxQtyOfDirectors();
    }

    function qtyOfDirectors() external view returns (uint256) {
        return _bod.qtyOfDirectors();
    }

    function appointmentCounter(uint40 appointer)
        external
        view
        returns (uint8 qty)
    {
        return _bod.appointmentCounter(appointer);
    }

    function isDirector(uint40 acct) external view returns (bool flag) {
        return _bod.isDirector(acct);
    }

    function inTenure(uint40 acct) external view returns (bool) {
        return _bod.inTenure(acct);
    }

    function whoIs(uint8 title) external view returns (uint40) {
        return _bod.whoIs(title);
    }

    function titleOfDirector(uint40 acct) external view returns (uint8) {
        return _bod.titleOfDirector(acct);
    }

    function appointerOfDirector(uint40 acct) external view returns (uint40) {
        return _bod.appointerOfDirector(acct);
    }

    function startBNOfDirector(uint40 acct) external view returns (uint32) {
        return _bod.startBNOfDirector(acct);
    }

    function endBNOfDirector(uint40 acct) external view returns (uint32) {
        return _bod.endBNOfDirector(acct);
    }

    function directors() external view returns (uint40[] memory) {
        return _bod.directors();
    }

    function isPrincipalOfDirector(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bod.isPrincipal(motionId, acct);
    }

    function isDelegateOfDirector(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bod.isDelegate(motionId, acct);
    }

    function delegateOfDirector(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40)
    {
        return _bod.delegateOf(motionId, acct);
    }

    function principalsOfDirector(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40[] memory)
    {
        return _bod.principalsOf(motionId, acct);
    }

    function billIsProposed(uint256 motionId) external view returns (bool) {
        return _bod.isProposed(motionId);
    }

    function headOfBill(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory)
    {
        return _bod.headOf(motionId);
    }

    function votingRuleOfBill(uint256 motionId)
        external
        view
        returns (bytes32)
    {
        return _bod.votingRule(motionId);
    }

    function stateOfBill(uint256 motionId) external view returns (uint8) {
        return _bod.state(motionId);
    }

    function votedYeaOfBill(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bod.votedYea(motionId, acct);
    }

    function votedNayOfBill(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bod.votedNay(motionId, acct);
    }

    function votedAbsOfBill(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bod.votedAbs(motionId, acct);
    }

    function getYeaOfBill(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _bod.getYea(motionId);
    }

    function qtyOfYeaOfBill(uint256 motionId) external view returns (uint256) {
        return _bod.qtyOfYea(motionId);
    }

    function getNayOfBill(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _bod.getNay(motionId);
    }

    function qtyOfNayOfBill(uint256 motionId) external view returns (uint256) {
        return _bod.qtyOfNay(motionId);
    }

    function getAbsOfBill(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _bod.getAbs(motionId);
    }

    function qtyOfAbsOfBill(uint256 motionId) external view returns (uint256) {
        return _bod.qtyOfAbs(motionId);
    }

    function allVotersOfBill(uint256 motionId)
        external
        view
        returns (uint40[] memory)
    {
        return _bod.allVoters(motionId);
    }

    function qtyOfAllVotersOfBill(uint256 motionId)
        external
        view
        returns (uint256)
    {
        return _bod.qtyOfAllVoters(motionId);
    }

    function sumOfVoteAmtOfBill(uint256 motionId)
        external
        view
        returns (uint64)
    {
        return _bod.sumOfVoteAmt(motionId);
    }

    function isVotedForBill(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bod.isVoted(motionId, acct);
    }

    function getVoteOfBill(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint40 voter,
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        )
    {
        return _bod.getVote(motionId, acct);
    }

    function billIsPassed(uint256 motionId) external view returns (bool) {
        return _bod.isPassed(motionId);
    }

    function billIsExecuted(uint256 motionId) external view returns (bool) {
        return _bod.isExecuted(motionId);
    }

    function billIsRejected(uint256 motionId) external view returns (bool) {
        return _bod.isRejected(motionId);
    }

    // #############
    // ##   BOH   ##
    // #############

    function pointer() external view returns (address) {
        return _boh.pointer();
    }

    function hasTemplate(uint8 title) external view returns (bool flag) {
        return _boh.hasTemplate(title);
    }

    function getTermTemplate(uint8 title) external view returns (address temp) {
        return _boh.getTermTemplate(title);
    }

    function templateOfBOH(uint8 typeOfDoc) external view returns (address) {
        return _boh.template(typeOfDoc);
    }

    function shaIsRegistered(address body) external view returns (bool) {
        return _boh.isRegistered(body);
    }

    function counterOfSHAs() external view returns (uint32) {
        return _boh.counterOfDocs();
    }

    function shaIsPassedReview(address body) external view returns (bool) {
        return _boh.passedReview(body);
    }

    function shaIsCirculated(address body) external view returns (bool) {
        return _boh.isCirculated(body);
    }

    function qtyOfSHAs() external view returns (uint256) {
        return _boh.qtyOfDocs();
    }

    function shasList() external view returns (bytes32[] memory) {
        return _boh.docsList();
    }

    function getSHA(address body)
        external
        view
        returns (bytes32 sn, bytes32 docHash)
    {
        return _boh.getDoc(body);
    }

    function stateOfSHA(address body) external view returns (uint8) {
        return _boh.currentState(body);
    }

    function reviewDeadlineBNOfSHA(address body)
        external
        view
        returns (uint32)
    {
        return _boh.reviewDeadlineBNOf(body);
    }

    function votingDeadlineBNOfSHA(address body)
        external
        view
        returns (uint32)
    {
        return _boh.votingDeadlineBNOf(body);
    }

    //###############
    //##    BOM    ##
    //###############

    function isPrincipalOfMember(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bom.isPrincipal(motionId, acct);
    }

    function isDelegateOfMember(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bom.isDelegate(motionId, acct);
    }

    function delegateOfMember(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40)
    {
        return _bom.delegateOf(motionId, acct);
    }

    function principalsOfMember(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40[] memory)
    {
        return _bom.principalsOf(motionId, acct);
    }

    function motionIsProposed(uint256 motionId) external view returns (bool) {
        return _bom.isProposed(motionId);
    }

    function headOfMotion(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory)
    {
        return _bom.headOf(motionId);
    }

    function votingRuleOfMotion(uint256 motionId)
        external
        view
        returns (bytes32)
    {
        return _bom.votingRule(motionId);
    }

    function stateOfMotion(uint256 motionId) external view returns (uint8) {
        return _bom.state(motionId);
    }

    function votedYeaOfMotion(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bom.votedYea(motionId, acct);
    }

    function votedNayOfMotion(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bom.votedNay(motionId, acct);
    }

    function votedAbsOfMotion(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bom.votedAbs(motionId, acct);
    }

    function getYeaOfMotion(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _bom.getYea(motionId);
    }

    function qtyOfYeaOfMotion(uint256 motionId)
        external
        view
        returns (uint256)
    {
        return _bom.qtyOfYea(motionId);
    }

    function getNayOfMotion(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _bom.getNay(motionId);
    }

    function qtyOfNayOfMotion(uint256 motionId)
        external
        view
        returns (uint256)
    {
        return _bom.qtyOfNay(motionId);
    }

    function getAbsOfMotion(uint256 motionId)
        external
        view
        returns (uint40[] memory, uint64)
    {
        return _bom.getAbs(motionId);
    }

    function qtyOfAbsOfMotion(uint256 motionId)
        external
        view
        returns (uint256)
    {
        return _bom.qtyOfAbs(motionId);
    }

    function allVotersOfMotion(uint256 motionId)
        external
        view
        returns (uint40[] memory)
    {
        return _bom.allVoters(motionId);
    }

    function qtyOfAllVotersOfMotion(uint256 motionId)
        external
        view
        returns (uint256)
    {
        return _bom.qtyOfAllVoters(motionId);
    }

    function sumOfVoteAmtOfMotion(uint256 motionId)
        external
        view
        returns (uint64)
    {
        return _bom.sumOfVoteAmt(motionId);
    }

    function motionIsVoted(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _bom.isVoted(motionId, acct);
    }

    function getVoteOfMotion(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint40 voter,
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        )
    {
        return _bom.getVote(motionId, acct);
    }

    function motionIsPassed(uint256 motionId) external view returns (bool) {
        return _bom.isPassed(motionId);
    }

    function motionIsExecuted(uint256 motionId) external view returns (bool) {
        return _bom.isExecuted(motionId);
    }

    function motionIsRejected(uint256 motionId) external view returns (bool) {
        return _bom.isRejected(motionId);
    }

    // ###########
    // ##  BOO  ##
    // ###########

    function counterOfOptions() external view returns (uint40) {
        return _boo.counterOfOptions();
    }

    function isOption(bytes32 sn) external view returns (bool) {
        return _boo.isOption(sn);
    }

    function getOption(bytes32 sn)
        external
        view
        returns (
            uint40 rightholder,
            uint32 closingBN,
            uint64 paid,
            uint64 par,
            bytes32 hashLock
        )
    {
        return _boo.getOption(sn);
    }

    function isObligor(bytes32 sn, uint40 acct) external view returns (bool) {
        return _boo.isObligor(sn, acct);
    }

    function obligorsOfOption(bytes32 sn)
        external
        view
        returns (uint40[] memory)
    {
        return _boo.obligorsOfOption(sn);
    }

    function stateOfOption(bytes32 sn) external view returns (uint8) {
        return _boo.stateOfOption(sn);
    }

    function futures(bytes32 sn) external view returns (bytes32[] memory) {
        return _boo.futures(sn);
    }

    function pledges(bytes32 sn) external view returns (bytes32[] memory) {
        return _boo.pledges(sn);
    }

    function oracle(bytes32 sn, uint64 blockNumber)
        external
        view
        returns (uint32 d1, uint32 d2)
    {
        return _boo.oracle(sn, blockNumber);
    }

    function snList() external view returns (bytes32[] memory) {
        return _boo.snList();
    }

    //###############
    //##    BOP    ##
    //###############

    function pledgesOf(uint32 ssn) external view returns (bytes32[] memory) {
        return _bop.pledgesOf(ssn);
    }

    function counterOfPledges(uint32 ssn) external view returns (uint32) {
        return _bop.counterOfPledges(ssn);
    }

    function isPledge(bytes32 sn) external view returns (bool) {
        return _bop.isPledge(sn);
    }

    function getPledge(bytes32 sn)
        external
        view
        returns (
            uint40 creditor,
            uint64 pledgedPar,
            uint64 guaranteedAmt
        )
    {
        return _bop.getPledge(sn);
    }

    //###############
    //##    BOS    ##
    //###############

    function verifyRegNum(string memory regNum) external view returns (bool) {
        return _bos.verifyRegNum(regNum);
    }

    function counterOfShares() external view returns (uint32) {
        return _bos.counterOfShares();
    }

    function counterOfClasses() external view returns (uint16) {
        return _bos.counterOfClasses();
    }

    function isShare(uint32 ssn) external view returns (bool) {
        return _bos.isShare(ssn);
    }

    function cleanPar(uint32 ssn) external view returns (uint64) {
        return _bos.cleanPar(ssn);
    }

    function getShare(uint32 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint64 paid,
            uint64 par,
            uint32 paidInDeadline,
            uint8 state
        )
    {
        return _bos.getShare(ssn);
    }

    function getLocker(uint32 ssn)
        external
        view
        returns (uint64 amount, bytes32 hashLock)
    {
        return _bos.getLocker(ssn);
    }

    function membersOfClass(uint16 class)
        external
        view
        returns (uint40[] memory)
    {
        return _bosCal.membersOfClass(class);
    }

    function sharesOfClass(uint16 class)
        external
        view
        returns (bytes32[] memory)
    {
        return _bosCal.sharesOfClass(class);
    }

    // #############
    // ##   ROM   ##
    // #############

    function maxQtyOfMembers() external view returns (uint16) {
        return _rom.maxQtyOfMembers();
    }

    function paidCap() external view returns (uint64) {
        return _rom.paidCap();
    }

    function parCap() external view returns (uint64) {
        return _rom.parCap();
    }

    function capAtBlock(uint64 blocknumber)
        external
        view
        returns (uint64, uint64)
    {
        return _rom.capAtBlock(blocknumber);
    }

    function totalVotes() external view returns (uint64) {
        return _rom.totalVotes();
    }

    function sharesList() external view returns (bytes32[] memory) {
        return _rom.sharesList();
    }

    function sharenumberExist(bytes32 sharenumber)
        external
        view
        returns (bool)
    {
        return _rom.sharenumberExist(sharenumber);
    }

    function isMember(uint40 acct) public view returns (bool) {
        return _rom.isMember(acct);
    }

    function paidOfMember(uint40 acct) external view returns (uint64 paid) {
        return _rom.paidOfMember(acct);
    }

    function parOfMember(uint40 acct) external view returns (uint64 par) {
        return _rom.parOfMember(acct);
    }

    function votesInHand(uint40 acct) external view returns (uint64) {
        return _rom.votesInHand(acct);
    }

    function votesAtBlock(uint40 acct, uint64 blocknumber)
        external
        view
        returns (uint64)
    {
        return _rom.votesAtBlock(acct, blocknumber);
    }

    function sharesInHand(uint40 acct)
        external
        view
        returns (bytes32[] memory)
    {
        return _rom.sharesInHand(acct);
    }

    function groupNo(uint40 acct) external view returns (uint16) {
        return _rom.groupNo(acct);
    }

    function qtyOfMembers() external view returns (uint16) {
        return _rom.qtyOfMembers();
    }

    function membersList() external view returns (uint40[] memory) {
        return _rom.membersList();
    }

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        returns (bool)
    {
        return _rom.affiliated(acct1, acct2);
    }

    // ==== group ====

    function isGroup(uint16 group) public view returns (bool) {
        return _rom.isGroup(group);
    }

    function counterOfGroups() external view returns (uint16) {
        return _rom.counterOfGroups();
    }

    function controllor() external view returns (uint40) {
        return _rom.controllor();
    }

    function votesOfController() external view returns (uint64) {
        return _rom.votesOfController();
    }

    function votesOfGroup(uint16 group) external view returns (uint64) {
        return _rom.votesOfGroup(group);
    }

    function leaderOfGroup(uint16 group) external view returns (uint64) {
        return _rom.leaderOfGroup(group);
    }

    function membersOfGroup(uint16 group)
        external
        view
        returns (uint40[] memory)
    {
        return _rom.membersOfGroup(group);
    }

    function deepOfGroup(uint16 group) external view returns (uint16) {
        return _rom.deepOfGroup(group);
    }

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _rom.getSnapshot();
    }
}
