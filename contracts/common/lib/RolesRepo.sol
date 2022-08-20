/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library RolesRepo {
    bytes32 constant KEEPERS = keccak256("Keepers");
    bytes32 constant ATTORNEYS = keccak256("Attorneys");

    struct Data {
        mapping(uint40 => bool) isMember;
        uint40 admin;
    }

    struct Roles {
        uint40[3] managers; // 0-Owner; 1-Bookeeper; 2-GeneralCounsel
        // NameOfRole => Data
        mapping(bytes32 => Data) roles;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setManager(
        Roles storage self,
        uint8 title,
        uint40 acct
    ) internal {
        self.managers[title] = acct;

        // ==== BooKeeper ====
        if (title == 1) {
            self.roles[KEEPERS].admin = acct;
            // ==== GeneralCounsel ====
        } else if (title == 2) {
            self.roles[ATTORNEYS].admin = acct;
        }
    }

    // ==== role ====

    function grantRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {
        require(originator == roleAdmin(self, role), "originator not admin");
        self.roles[role].isMember[acct] = true;
    }

    function revokeRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {
        require(originator == roleAdmin(self, role), "originator not admin");

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
        require(role == KEEPERS, "KEEPERS cannot be abandoned");

        require(
            originator == self.managers[0] ||
                originator == roleAdmin(self, role),
            "originator not owner or roleAdmin"
        );

        delete self.roles[role];
    }

    // very important API for role admin setting, which shall be only exposed to AccessControl func.
    function setRoleAdmin(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {
        if (role == KEEPERS)
            require(originator == self.managers[1], "originator not bookeeper");
        else require(originator == self.managers[0], "originator not owner");

        self.roles[role].admin = acct;
    }

    function _removeRole(
        Roles storage self,
        bytes32 role,
        uint40 acct
    ) private {
        delete self.roles[role].isMember[acct];
    }

    function copyRoleTo(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        Roles storage to
    ) internal returns (bool) {
        if (role == KEEPERS)
            require(originator == self.managers[0], "originator not owner");
        else if (role == ATTORNEYS)
            require(originator == self.managers[0], "originator not owner");

        to.roles[role] = self.roles[role];

        return true;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isManager(
        Roles storage self,
        uint8 title,
        uint40 acct
    ) internal view returns (bool) {
        require(title < 3, "title overflow");
        return self.managers[title] == acct;
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
