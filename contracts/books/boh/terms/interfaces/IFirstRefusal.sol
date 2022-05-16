/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

contract IFirstRefusal {
    function setFirstRefusal(
        uint8 typeOfDeal,
        bool membersEqualOfFR,
        bool proRata,
        bool basedOnPar
    ) external;

    function delFirstRefusal(uint8 typeOfDeal) external;

    function addRightholder(uint8 typeOfDeal, address rightholder) external;

    function removeRightholder(uint8 typeOfDeal, address acct) external;

    // ################
    // ##  查询接口  ##
    // ################

    function ruleOfFR(uint8 typeOfDeal) public view returns (bytes32);

    function isRightholder(uint8 typeOfDeal, address acct)
        public
        view
        returns (bool);

    function rightholders(uint8 typeOfDeal) public view returns (address[]);

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool);

    function isExempted(address ia, bytes32 sn) external view returns (bool);
}
