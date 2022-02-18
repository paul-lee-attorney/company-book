/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

interface IShareholdersAgreement {
    //##############
    //##  Event   ##
    //##############

    event AddTermToFolder(uint8 indexed typeOfDeal, uint8 title);

    event RemoveTermFromFolder(uint8 indexed typeOfDeal, uint8 title);

    event SetTemplate(uint8 indexed title, address tempAdd);

    event RemoveTemplate(uint8 indexed title);

    event AddBook(address book);

    event RemoveBook();

    event CreateTerm(
        uint8 indexed title,
        address indexed body,
        address creator
    );

    event RemoveTerm(uint8 indexed title);

    //##################
    //##    写接口    ##
    //##################

    function addTermToFolder(uint8 typeOfDeal, uint8 title) external;

    function removeTermFromFolder(uint8 typeOfDeal, uint8 title) external;

    function setTermsTemplate(address[18] templates) external;

    function removeTemplate(uint8 title) external;

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    //##################
    //##    读接口    ##
    //##################

    function getTerm(uint8 title) external view returns (address body);

    function getTerms() external view returns (address[] terms);

    function getCheckList(uint8 typeOfDeal)
        external
        view
        returns (uint8[] titles);

    function getTemplate(uint8 title) external view returns (address);

    function getBooks() external view returns (address[]);

    function termIsTriggered(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) public view returns (bool);

    function dealIsTriggered(
        address ia,
        uint8 snOfDeal,
        uint8 typeOfDeal
    ) public view returns (bool flag, uint8[] triggers);

    function termIsExempted(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) public returns (bool);

    function dealIsExempted(
        address ia,
        uint8 snOfDeal,
        uint8 typeOfDeal
    ) public view returns (bool flag, uint8[] triggers);
}
