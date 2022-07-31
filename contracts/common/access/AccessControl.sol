/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./IAccessControl.sol";
import "./RegCenterSetting.sol";

contract AccessControl is IAccessControl, RegCenterSetting {
    bool internal _finalized;

    bytes32 constant KEEPERS = keccak256("Keepers");
    bytes32 constant ATTORNEYS = keccak256("Attorneys");

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyManager(uint8 title) {
        require(_rc.isManager(title, msg.sender), "not the specific manager");
        _;
    }

    modifier onlyOwnerOrBookeeper() {
        require(
            _rc.isManager(0, msg.sender) || _rc.isManager(1, msg.sender),
            "neither owner nor bookeeper"
        );
        _;
    }

    modifier onlyKeeper() {
        require(_rc.hasRole(KEEPERS, msg.sender), "not Keeper");
        _;
    }

    modifier onlyAttorney() {
        require(_rc.hasRole(ATTORNEYS, msg.sender), "not Attorney");
        _;
    }

    modifier attorneyOrKeeper() {
        require(
            _rc.hasRole(ATTORNEYS, msg.sender) ||
                _rc.hasRole(KEEPERS, msg.sender),
            "not Attorney or Bookeeper"
        );
        _;
    }

    // ==== DocState ====

    modifier onlyPending() {
        require(!_finalized, "Doc is _finalized");
        _;
    }

    modifier onlyFinalized() {
        require(_finalized, "Doc is still pending");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        uint8 roleOfUser,
        uint40 entity
    ) public {
        _setRegCenter(regCenter);

        _rc.regUser(roleOfUser, entity);

        _rc.setManager(0, msg.sender, owner);
        _rc.setManager(1, msg.sender, directKeeper);

        emit Init(owner, directKeeper, _rc);
    }

    // function regThisContract(uint8 roleOfUser, uint40 entity) public {
    //     uint40 userNo = _rc.regUser(roleOfUser, entity);
    //     emit RegThisContract(userNo);
    // }

    function setManager(uint8 title, address acct)
        external
        onlyOwnerOrBookeeper
    {
        _rc.setManager(title, msg.sender, acct);
        emit SetManager(title, msg.sender, acct);
    }

    function lockContents() public onlyPending {
        _rc.abandonRole(ATTORNEYS, msg.sender);
        _rc.setManager(2, msg.sender, address(0));
        _finalized = true;

        emit LockContents();
    }

    function quitEntity(uint8 roleOfUser) external onlyManager(0) {
        _rc.quitEntity(roleOfUser);

        emit QuitEntity(roleOfUser);
    }

    function _copyRoleTo(bytes32 role, address to) internal onlyManager(1) {
        _rc.copyRoleTo(role, msg.sender, to);

        emit CopyRoleTo(role, to);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getManager(uint8 title) public view returns (uint40) {
        return _rc.getManager(title);
    }

    function getManagerKey(uint8 title) public view returns (address) {
        return _rc.getManagerKey(title);
    }

    function finalized() external view returns (bool) {
        return _finalized;
    }
}
