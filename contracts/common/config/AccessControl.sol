/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./Roles.sol";
import "./KeyPerson.sol";

contract AccessControl is Roles {
    bytes32 public constant OWNER = bytes32("Owner");

    bytes32 public constant DIRECT_KEEPER = bytes32("DirectKeeper");

    bytes32 public constant KEEPERS = bytes32("Keepers");

    bytes32 public constant USERS = bytes32("Users");

    // ##################
    // ##   Event      ##
    // ##################

    event Init(address indexed admin, address indexed bookeeper);

    event AbandonOwnership();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyOwner() {
        require(msg.sender == primaryKey(OWNER), "not owner");
        _;
    }

    modifier onlyDirectKeeper() {
        require(msg.sender == primaryKey(DIRECT_KEEPER), "not direct keeper");
        _;
    }

    modifier onlyKeeper() {
        require(hasRole(KEEPERS, msg.sender), "not Keeper");
        _;
    }

    modifier ownerOrDirectKeeper() {
        require(
            msg.sender == primaryKey(OWNER) ||
                msg.sender == primaryKey(DIRECT_KEEPER)
        );
        _;
    }

    modifier keeperOrUser() {
        require(
            hasRole(KEEPERS, msg.sender) || hasRole(USERS, msg.sender),
            "not KEEPER or OWNER"
        );
        _;
    }

    modifier currentDate(uint256 date) {
        require(
            date >= now - 15 minutes && date <= now + 15 minutes,
            "not a current date"
        );
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(address owner, address directKeeper) public {
        _setPrimaryKey(OWNER, owner);
        _setPrimaryKey(DIRECT_KEEPER, directKeeper);
        _setRoleAdmin(KEEPERS, DIRECT_KEEPER);
        _setRoleAdmin(USERS, OWNER);

        emit Init(owner, directKeeper);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() public view keeperOrUser returns (address) {
        return primaryKey(OWNER);
    }

    function getDirectKeeper() public view keeperOrUser returns (address) {
        return primaryKey(DIRECT_KEEPER);
    }
}
