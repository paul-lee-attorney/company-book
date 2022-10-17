// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface ILockUp {
    // ################
    // ##   Event   ##
    // ################

    event SetLocker(uint32 indexed ssn, uint32 dueDate);

    event UpdateLocker(uint32 indexed ssn, uint32 dueDate);

    event AddKeyholder(uint32 indexed ssn, uint40 keyholder);

    event RemoveKeyholder(uint32 indexed ssn, uint40 keyholder);

    event DelLocker(uint32 indexed ssn);

    // ################
    // ##   Write    ##
    // ################

    function setLocker(uint32 ssn, uint32 dueDate) external;

    function updateLocker(uint32 ssn, uint32 dueDate) external;

    function delLocker(uint32 ssn) external;

    function addKeyholder(uint32 ssn, uint40 keyholder) external;

    function removeKeyholder(uint32 ssn, uint40 keyholder) external;

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint32 ssn) external view returns (bool);

    function getLocker(uint32 ssn)
        external
        view
        returns (uint32 dueDate, uint40[] memory keyHolders);

    function lockedShares() external view returns (uint32[] memory);
}
