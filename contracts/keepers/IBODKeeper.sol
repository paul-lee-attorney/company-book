/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

interface IBODKeeper {
    function appointDirector(
        uint40 acct,
        uint8 title,
        uint40 appointer
    ) external;

    function removeDirector(uint40 director, uint40 appointer) external;

    function quitPosition(uint40 director) external;

    function nominateDirector(uint40 candidate, uint40 nominator) external;

    function takePosition(uint40 candidate, uint256 motionId) external;
}
