/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

interface IBookOfDirectors {
    event SetNumOfDirectors(uint256 num);

    event AddDirector(
        uint40 acct,
        uint8 title,
        uint40 nominator,
        uint32 inaugurationDate,
        uint32 expirationDate
    );

    event RemoveDirector(uint40 userNo, uint8 title);

    //##################
    //##    写接口    ##
    //##################

    function setNumOfDirectors(uint256 num) external;

    function addDirector(
        uint40 nominator,
        uint40 acct,
        uint8 title
    ) external;

    function removeDirector(uint40 acct) external;

    //##################
    //##    读接口    ##
    //##################

    function maxNumOfDirectors() external view returns (uint256);

    function isDirector(uint40 acct) external view returns (bool);

    function whoIs(uint8 title) external view returns (uint40);

    function titleOfDirector(uint40 acct) external view returns (uint8);

    function nominatorOfDirector(uint40 acct) external view returns (uint40);

    function inaugurationDateOfDirector(uint40 acct)
        external
        view
        returns (uint32);

    function expirationDateOfDirector(uint40 acct)
        external
        view
        returns (uint32);

    function qtyOfDirectors() external view returns (uint256);

    function directors() external view returns (uint40[]);
}
