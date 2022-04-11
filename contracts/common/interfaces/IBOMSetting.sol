/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IBOMSetting {
    event SetBOM(address bom);

    function setBOM(address bom) external;

    // function getBOM() external view returns (IBookOfMotions);
}
