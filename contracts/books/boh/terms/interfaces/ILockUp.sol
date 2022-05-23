/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../LockUp.sol";

contract ILockUp {
    function setLocker(uint256 shareNumber, uint256 dueDate) external;

    function delLocker(uint256 shareNumber) external;

    function addKeyholder(uint256 shareNumber, uint32 keyholder) external;

    function removeKeyholder(uint256 shareNumber, uint32 keyholder) external;

    // ################
    // ##  查询接口  ##
    // ################

    function lockerExist(uint256 shareNumber) public view returns (bool);

    function getLocker(uint256 shareNumber)
        public
        view
        returns (uint256 dueDate, uint32[] keyHolders);
}
