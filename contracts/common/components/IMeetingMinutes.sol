// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/MotionsRepo.sol";

interface IMeetingMinutes {

    //##################
    //##    events    ##
    //##################

    event EntrustDelegate(uint256 indexed motionId, uint40 authorizer, uint40 delegate);

    event ProposeAction(uint256 indexed actionId, uint8 actionType, uint40 submitter);

    event VoteCounting(uint256 indexed motionId, uint8 state);

    event ExecuteAction(uint256 indexed motionId, bool flag);

    //##################
    //##    写接口    ##
    //##################

    // ==== delegate ====

    function entrustDelegate(
        uint40 authorizer,
        uint40 delegate,
        uint256 motionId
    ) external;

    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter
    ) external;

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 motionId) external;

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external returns (uint256);

    //##################
    //##    Read     ##
    //################

    // ==== delegate ====

    function isPrincipal(uint256 motionId, uint40 acct) external view returns(bool);

    function isDelegate(uint256 motionId, uint40 acct) external view returns(bool);

    function delegateOf(uint256 motionId, uint40 acct) external view returns(uint40);

    function principalsOf(uint256 motionId, uint40 acct) external view returns(uint40[] memory);

    // ==== motion ====

    function isProposed(uint256 motionId) external view returns(bool);

    function headOf(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory);

    function votingRule(uint256 motionId)
        external
        view
        returns (bytes32);

    function state(uint256 motionId)
        external
        view
        returns (uint8);

    // ==== voting ====

    function votedYea(uint256 motionId, uint40 acct)
        external
        view
        returns (bool);

    function votedNay(uint256 motionId, uint40 acct)
        external
        view
        returns (bool);

    function votedAbs(uint256 motionId, uint40 acct)
        external
        view
        returns (bool);

    function getYea(uint256 motionId) external view returns (uint40[] memory, uint64);

    function qtyOfYea(uint256 motionId)
        external
        view
        returns (uint256);

    function getNay(uint256 motionId) external view returns (uint40[] memory, uint64);

    function qtyOfNay(uint256 motionId)
        external
        view
        returns (uint256);

    function getAbs(uint256 motionId) external view returns (uint40[] memory, uint64);

    function qtyOfAbs(uint256 motionId)
        external
        view
        returns (uint256);

    function allVoters(uint256 motionId)
        external
        view
        returns (uint40[] memory);

    function qtyOfAllVoters(uint256 motionId)
        external
        view
        returns (uint256);

    function sumOfVoteAmt(uint256 motionId) external view returns (uint64);

    function isVoted(uint256 motionId, uint40 acct) external view returns (bool);

    function getVote(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint40 voter,
            uint64 weight,
            uint8 attitude,
            uint32 blockNumber,
            uint32 sigDate,
            bytes32 sigHash);

    function isPassed(uint256 motionId)
        external
        view
        returns (bool);

    function isExecuted(uint256 motionId)
        external
        view
        returns (bool);

    function isRejected(uint256 motionId)
        external
        view
        returns (bool);
}
