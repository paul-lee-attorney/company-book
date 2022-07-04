/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

interface IBookOfDirectors {
    event SetMaxNumOfDirectors(uint8 num);

    event AddDirector(
        uint40 acct,
        uint8 title,
        uint40 appointer,
        uint32 inaugurationDate,
        uint32 expirationDate
    );

    event RemoveDirector(uint40 userNo, uint8 title);

    event ProposeMotion(
        uint256 indexed motionId,
        uint8 typeOfMotion,
        address[] targets,
        bytes[] params,
        bytes32 desHash,
        bytes32 sn
    );

    event Vote(
        uint256 indexed motionId,
        uint40 voter,
        uint8 atitude,
        uint256 voteAmt
    );

    event VoteCounting(uint256 indexed motionId, uint8 result);

    event ExecuteAction(uint256 indexed actionId, bool flag);

    //##################
    //##    写接口    ##
    //##################

    function setMaxNumOfDirectors(uint8 num) external;

    function appointDirector(
        uint40 appointer,
        uint40 candidate,
        uint8 title
    ) external;

    function takePosition(uint40 candidate) external;

    function removeDirector(uint40 acct) external;

    //##################
    //##    读接口    ##
    //##################

    function maxNumOfDirectors() external view returns (uint8);

    function appointmentCounter(uint40 appointer) external view returns (uint8);

    function isDirector(uint40 acct) external view returns (bool);

    function whoIs(uint8 title) external view returns (uint40);

    function titleOfDirector(uint40 acct) external view returns (uint8);

    function appointerOfDirector(uint40 acct) external view returns (uint40);

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
