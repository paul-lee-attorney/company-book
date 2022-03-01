/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../TagAlong.sol";

interface ITagAlong {
    function addMemberToGroup(uint8 groupID, address member) external;

    function removeMemberFromGroup(uint8 groupID, address member) external;

    function delGroup(uint8 groupID) external;

    function setTag(
        uint8 dragerID,
        uint8 triggerType,
        uint256 threshold,
        bool proRata
    ) external;

    function addFollower(uint8 dragerID, address follower) external;

    function removeFollower(uint8 dragerID, address follower) external;

    function delTag(uint8 dragerID) external;

    // ################
    // ##  查询接口  ##
    // ################

    function getQtyOfGroups() external view returns (uint8);

    function getGroupNumOf(address seller) external view returns (uint8);

    function getMembersOfGroup(uint8 groupID) external view returns (address[]);

    function tagExist(address seller) external view returns (bool);

    function getTag(address seller)
        external
        view
        returns (
            address[] followers,
            uint8 triggerType,
            uint256 threshold,
            bool proRata
        );
}
