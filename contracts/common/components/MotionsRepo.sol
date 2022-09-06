/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../../common/access/AccessControl.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/ObjsRepo.sol";

import "./IMotionsRepo.sol";

contract MotionsRepo is IMotionsRepo, AccessControl {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using ObjsRepo for ObjsRepo.BallotsBox;

    struct Motion {
        bytes32 sn;
        bytes32 votingRule;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(not to buy) 4-rejected (to buy)
        ObjsRepo.BallotsBox box;
    }

    // motionId => delegateNo => userNo
    mapping(uint256 => mapping(uint40 => EnumerableSet.UintSet))
        internal _delegates;

    // motionId => authorizers
    mapping(uint256 => EnumerableSet.UintSet) internal _authorizers;

    // motionId => Motion
    mapping(uint256 => Motion) internal _motions;

    EnumerableSet.UintSet internal _motionIds;

    //##############
    //##  Event   ##
    //##############

    event AuthorizeDelegate(
        uint40 rightholder,
        uint40 delegate,
        uint256 motionId
    );

    event ProposeMotion(
        uint256 indexed motionId,
        uint8 typeOfMotion,
        address[] targets,
        bytes[] params,
        bytes32 desHash,
        bytes32 sn
    );

    event CastVote(
        uint256 indexed motionId,
        uint40 voter,
        uint8 atitude,
        uint64 voteAmt
    );

    event ExecuteAction(uint256 indexed motionId, bool flag);

    //####################
    //##    modifier    ##
    //####################

    modifier onlyProposed(uint256 motionId) {
        require(_motionIds.contains(motionId), "motion is NOT proposed");
        _;
    }

    modifier beforeExpire(uint256 motionId) {
        require(
            _motions[motionId].sn.votingDeadlineBNOfMotion() >= block.number,
            "missed voting deadline"
        );
        _;
    }

    modifier afterExpire(uint256 motionId) {
        require(
            _motions[motionId].sn.votingDeadlineBNOfMotion() < block.number,
            "MR.Mo.afterExpire: still on voting"
        );
        _;
    }

    modifier notVotedTo(uint256 motionId, uint40 caller) {
        require(
            !_motions[motionId].box.isVoted(caller),
            "HAVE voted for the motion"
        );
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _authorizeDelegate(
        uint40 authorizer,
        uint40 delegate,
        uint256 motionId
    ) internal {
        require(
            _motions[motionId].state == uint8(EnumsRepo.StateOfMotion.Pending),
            "action has been proposed"
        );

        if (_authorizers[motionId].add(authorizer)) {
            _delegates[motionId][delegate].add(authorizer);
            emit AuthorizeDelegate(authorizer, delegate, motionId);
        }
    }

    function _createSN(
        uint8 typeOfMotion,
        uint40 submitter,
        uint32 proposeBN,
        uint32 votingDeadlineBN,
        uint32 weightRegBN,
        uint40 candidate
    ) internal pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfMotion);
        _sn = _sn.acctToSN(1, submitter);
        _sn = _sn.dateToSN(6, proposeBN);
        _sn = _sn.dateToSN(10, votingDeadlineBN);
        _sn = _sn.dateToSN(14, weightRegBN);

        _sn = _sn.acctToSN(18, candidate);

        sn = _sn.bytesToBytes32();
    }

    function _proposeMotion(
        uint256 motionId,
        bytes32 rule,
        bytes32 sn,
        uint8 motionType,
        address[] targets,
        bytes[] params,
        bytes32 desHash
    ) internal {
        require(!_motionIds.contains(motionId), "the motion has been proposed");

        Motion storage motion = _motions[motionId];

        motion.votingRule = rule;
        motion.sn = sn;
        motion.state = uint8(EnumsRepo.StateOfMotion.Proposed);

        _motionIds.add(motionId);

        emit ProposeMotion(motionId, motionType, targets, params, desHash, sn);
    }

    // function _hashAction(
    //     uint8 actionType,
    //     address[] target,
    //     bytes[] params,
    //     bytes32 desHash
    // ) internal pure returns (uint256) {
    //     return
    //         uint256(keccak256(abi.encode(actionType, target, params, desHash)));
    // }

    function _castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash,
        uint64 voteAmt
    ) internal notVotedTo(motionId, caller) beforeExpire(motionId) {
        Motion storage motion = _motions[motionId];

        if (motion.box.add(caller, attitude, voteAmt, sigHash)) {
            emit CastVote(motionId, caller, attitude, voteAmt);
        }
    }

    // function _toBytes(bytes32[] input) internal pure returns (bytes[]) {
    //     uint256 len = input.length;
    //     bytes[] memory output = new bytes[](len);

    //     while (len > 0) {
    //         output[len - 1] = abi.encodePacked(input[len - 1]);
    //         len--;
    //     }

    //     return output;
    // }

    // function execAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash
    // ) external onlyManager(1) returns (uint256) {
    //     bytes[] memory paramsBytes = _toBytes(params);

    //     uint256 motionId = _hashAction(
    //         actionType,
    //         targets,
    //         paramsBytes,
    //         desHash
    //     );

    //     require(_motionIds.contains(motionId), "motion not proposed");

    //     Motion storage motion = _motions[motionId];

    //     require(
    //         motion.state == uint8(EnumsRepo.StateOfMotion.Passed),
    //         "voting NOT end"
    //     );

    //     motion.state = uint8(EnumsRepo.StateOfMotion.Executed);
    //     if (_execute(targets, paramsBytes)) emit ExecuteAction(motionId, true);
    //     else emit ExecuteAction(motionId, false);

    //     return motionId;
    // }

    // function _execute(address[] memory targets, bytes[] memory params)
    //     private
    //     returns (bool)
    // {
    //     bool success;

    //     for (uint256 i = 0; i < targets.length; i++) {
    //         success = targets[i].call(params[i]);
    //         if (!success) return success;
    //     }

    //     return success;
    // }

    //##################
    //##    读接口    ##
    //##################

    function serialNumber(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        returns (bytes32)
    {
        return _motions[motionId].sn;
    }

    function votingRule(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        returns (bytes32)
    {
        return _motions[motionId].votingRule;
    }

    function state(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        returns (uint8)
    {
        return _motions[motionId].state;
    }

    function votedYea(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _motions[motionId].box.votedYea(acct);
    }

    function votedNay(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _motions[motionId].box.votedNay(acct);
    }

    function getYea(uint256 motionId) external view returns (uint40[], uint64) {
        return _motions[motionId].box.getYea();
    }

    function getNay(uint256 motionId) external view returns (uint40[], uint64) {
        return _motions[motionId].box.getNay();
    }

    function sumOfVoteAmt(uint256 motionId) external view returns (uint64) {
        return _motions[motionId].box.sumOfWeight;
    }

    function isVoted(uint256 motionId, uint40 acct) public view returns (bool) {
        return _motions[motionId].box.isVoted(acct);
    }

    function getVote(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash
        )
    {
        require(_motions[motionId].box.isVoted(acct), "did NOT vote");

        return _motions[motionId].box.getVote(acct);
    }

    function isPassed(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        returns (bool)
    {
        return
            _motions[motionId].state == uint8(EnumsRepo.StateOfMotion.Passed);
    }

    function isRejected(uint256 motionId)
        external
        view
        onlyProposed(motionId)
        returns (bool)
    {
        return _motions[motionId].state > uint8(EnumsRepo.StateOfMotion.Passed);
    }
}
