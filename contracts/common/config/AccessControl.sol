/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./Roles.sol";
import "./KeyPerson.sol";

import "../lib/ArrayUtils.sol";

contract AccessControl is Roles {
    using ArrayUtils for address[];

    bytes32 internal constant _OWNER = bytes32("Owner");

    bytes32 internal constant _DIRECT_KEEPER = bytes32("DirectKeeper");

    bytes32 internal constant _KEEPERS = bytes32("Keepers");

    bytes32 internal constant _USERS = bytes32("Users");

    // ##################
    // ##   Event      ##
    // ##################

    event Init(address indexed admin, address indexed bookeeper);

    event AbandonOwnership();

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyOwner() {
        require(msg.sender == _primaryKey(_OWNER), "not owner");
        _;
    }

    modifier onlyDirectKeeper() {
        require(msg.sender == _primaryKey(_DIRECT_KEEPER), "not direct keeper");
        _;
    }

    modifier onlyKeeper() {
        require(hasRole(_KEEPERS, msg.sender), "not Keeper");
        _;
    }

    modifier ownerOrDirectKeeper() {
        require(
            msg.sender == _primaryKey(_OWNER) ||
                msg.sender == _primaryKey(_DIRECT_KEEPER)
        );
        _;
    }

    modifier keeperOrUser() {
        require(
            hasRole(_KEEPERS, msg.sender) || hasRole(_USERS, msg.sender),
            "not KEEPER or _OWNER"
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
        _setPrimaryKey(_OWNER, owner);
        _setPrimaryKey(_DIRECT_KEEPER, directKeeper);
        _setRoleAdmin(_KEEPERS, _DIRECT_KEEPER);
        _setRoleAdmin(_USERS, _OWNER);

        emit Init(owner, directKeeper);
    }

    // function abandonOwnership() external onlyOwner {
    //     _quitPositon(_OWNER);
    //     emit AbandonOwnership();
    // }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() public view keeperOrUser returns (address) {
        return _primaryKey(_OWNER);
    }

    function getDirectKeeper() public view keeperOrUser returns (address) {
        return _primaryKey(_DIRECT_KEEPER);
    }
}
