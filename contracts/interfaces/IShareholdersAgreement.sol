/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IShareholdersAgreement {
    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[18] templates) external;

    function setBOS(address bos) external;

    function setBOM(address bom) external;

    function removeTemplate(uint8 title) external;

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    function finalizeSHA() external;

    //##################
    //##    读接口    ##
    //##################

    function getTerm(uint8 title) external view returns (address body);

    function terms() external view returns (address[]);

    function tempOfTitle(uint8 title) external view returns (address);

    function bos() external view returns (address);

    function bom() external view returns (address);

    function termIsTriggered(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) external returns (bool);
}
