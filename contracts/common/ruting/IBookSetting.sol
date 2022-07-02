/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookSetting {
    //##############
    //##  Event   ##
    //##############

    event SetBOA(address boa);

    event SetBOD(address bod);

    event SetBOH(address boh);

    event SetBOM(address bom);

    event SetBOO(address boo);

    event SetBOP(address bop);

    event SetBOS(address bos);

    event SetBOSCal(address cal);

    //##############
    //##  write   ##
    //##############

    function setBOS(address bos) external;

    function setBOSCal(address bosCal) external;

    function setBOA(address boa) external;

    function setAgrmtCal(address agrmtCal) external;

    function setBOH(address boh) external;

    function setBOM(address bom) external;

    function setBOO(address boo) external;

    function setBOP(address boo) external;
}
