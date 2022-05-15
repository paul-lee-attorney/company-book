/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../LockUp.sol";

contract ILockUp {
    function setLocker(uint shareNumber, uint dueDate) external;

    function delLocker(uint shareNumber) external;

    function addKeyholder(uint shareNumber, address keyholder) external;

    function removeKeyholder(uint shareNumber, address keyholder) external;

    // ################
    // ##  查询接口  ##
    // ################

    function lockerExist(uint shareNumber) public view returns (bool);

    function getLocker(uint shareNumber)
        public
        view
        returns (uint dueDate, address[] keyHolders);
}
