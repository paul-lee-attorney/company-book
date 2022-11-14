// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library RolesRepo {
    bytes32 constant ATTORNEYS = bytes32("Attorneys");

    struct GroupOfRole {
        mapping(uint40 => bool) isMember;
        uint40 admin;
    }

    struct Roles {
        uint8 state; // 0-pending; 1-initiated; 2-finalized
        uint40[6] managers; // 0-owner; 1-generalCounsel; ...
        mapping(bytes32 => GroupOfRole) roles;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setManager(
        Roles storage self,
        uint8 title,
        uint40 originator,
        uint40 acct
    ) internal {

        if (self.state == 0) self.state = 1;
        else require(originator == self.managers[0], 
            "RR.setManager: originator not owner");

        self.managers[title] = acct;

        // ==== GeneralCounsel ====
        if (title == 1) {
            self.roles[ATTORNEYS].admin = acct;
            self.roles[ATTORNEYS].isMember[acct] = true;
        }
    }

    // ==== role ====

    function grantRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {
        require(
            originator == roleAdmin(self, role),
            "RR.grantRole: originator not admin"
        );
        self.roles[role].isMember[acct] = true;
    }

    function revokeRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {
        require(originator == roleAdmin(self, role), "RR.revokeRole: originator not admin");

        delete self.roles[role].isMember[acct];
    }

    function renounceRole(
        Roles storage self,
        bytes32 role,
        uint40 originator
    ) internal {
        delete self.roles[role].isMember[originator];
    }

    function abandonRole(
        Roles storage self,
        bytes32 role,
        uint40 originator
    ) internal {

        require(
            originator == self.managers[0] ||
                originator == roleAdmin(self, role),
            "RR.abandonRole: originator not owner or roleAdmin"
        );

        self.roles[role].admin = 0;
        delete self.roles[role];
    }

    // very important API for role admin setting, which shall be only exposed to AccessControl func.
    function setRoleAdmin(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {

        require(
            originator == self.managers[0],
            "RR.setRoleAdmin: originator not owner"
        );

        self.roles[role].admin = acct;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isManager(
        Roles storage self,
        uint8 title,
        uint40 acct
    ) internal view returns (bool) {
        return self.managers[title] == acct;
    }

    function getManager(
        Roles storage self,
        uint8 title
    ) internal view returns (uint40) {
        return self.managers[title];
    }

    function hasRole(
        Roles storage self,
        bytes32 role,
        uint40 acct
    ) internal view returns (bool) {
        return self.roles[role].isMember[acct];
    }

    function roleAdmin(Roles storage self, bytes32 role)
        internal
        view
        returns (uint40)
    {
        return self.roles[role].admin;
    }
}
