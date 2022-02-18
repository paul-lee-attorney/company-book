/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";

interface IBOSSetting {
    event SetBOS(address bos);

    function setBOS(address bos) external;

    function getBOS() external view returns (IBookOfShares);
}
