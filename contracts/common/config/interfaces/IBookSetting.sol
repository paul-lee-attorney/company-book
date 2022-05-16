/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookSetting {
    function setBOS(address bos) external;

    function setBOSCal(address bosCal) external;

    function setBOA(address boa) external;

    function setAgrmtCal(address agrmtCal) external;

    function setBOH(address boh) external;

    function setBOM(address bom) external;

    function setBOO(address boo) external;

    function setBOP(address boo) external;
}
