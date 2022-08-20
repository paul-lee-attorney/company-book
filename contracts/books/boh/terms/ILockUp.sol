/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

contract ILockUp {
    // ################
    // ##   Event   ##
    // ################

    event SetLocker(bytes32 indexed shareNumber, uint32 dueDate);

    event AddKeyholder(bytes32 indexed shareNumber, uint40 keyholder);

    event RemoveKeyholder(bytes32 indexed shareNumber, uint40 keyholder);

    event DelLocker(bytes32 indexed shareNumber);

    // ################
    // ##   Write    ##
    // ################

    function setLocker(bytes32 shareNumber, uint32 dueDate) external;

    function delLocker(bytes32 shareNumber) external;

    function addKeyholder(bytes32 shareNumber, uint40 keyholder) external;

    function removeKeyholder(bytes32 shareNumber, uint40 keyholder) external;

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint32 ssn) external view returns (bool);

    function getLocker(uint32 ssn)
        public
        view
        returns (uint32 dueDate, uint40[] keyHolders);

    function lockedShares() external view returns (bytes32[]);
}
