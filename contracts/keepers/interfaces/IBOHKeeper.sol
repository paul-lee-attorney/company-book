/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBOHKeeper {
    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(uint8 title, address add) external;

    function createSHA(uint8 docType) external returns (address body);

    function removeSHA(address body) external;

    function submitSHA(address body, bytes32 docHash) external;

    function effectiveSHA(address body) external;
}
