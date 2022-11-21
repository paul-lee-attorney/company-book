// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/MotionsRepo.sol";

import "../../common/components/IMeetingMinutes.sol";

interface IBookOfMotions is IMeetingMinutes {
    //##################
    //##    events    ##
    //##################

    event NominateDirector(
        uint256 indexed motionId,
        uint40 candidate,
        uint40 nominator
    );

    event ProposeIA(uint256 indexed motionId, address ia, uint40 submitter);

    //##################
    //##    写接口    ##
    //##################

    function createCorpSeal() external;

    function createBoardSeal(address bod) external;

    function setBooksOfCorp(address book) external;

    function nominateDirector(uint40 candidate, uint40 nominator) external;

    function proposeIA(address ia, uint40 submitter) external;

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        returns (uint64 paid, uint64 par);
}
