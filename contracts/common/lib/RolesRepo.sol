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
        uint40 originator,
        uint40 acct
    ) internal returns (bool) {
        require(originator > 0, "zero originator");

        // ==== Owner ====
        if (title == 0) {
            require(
                self.managers[0] == 0 ||
                    self.managers[0] == originator ||
                    self.managers[1] == originator,
                "originator is not owner"
            );
            self.managers[0] = acct;
            return true;

            // ==== Bookeeper ====
        } else if (title == 1) {
            require(
                self.managers[1] == 0 || self.managers[1] == originator,
                "originator is not Bookeeper"
            );
            require(acct > 0, "ZERO userNo");

            self.managers[1] = acct;
            self.roles[KEEPERS].admin = acct;

            return true;

            // ==== GeneralCounsel ====
        } else if (title == 2) {
            require(
                originator == self.managers[0] ||
                    originator == self.managers[1],
                "neither Owner nor Bookeeper"
            );
            self.managers[2] = acct;
            self.roles[ATTORNEYS].admin = acct;

            return true;
        } else return false;
    }

    // ==== role ====

    function grantRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal returns (bool) {
        require(originator == roleAdmin(self, role), "originator not admin");
        self.roles[role].isMember[acct] = true;
        return true;
    }

    function revokeRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal returns (bool) {
        require(originator == roleAdmin(self, role), "originator not admin");
        return _removeRole(self, role, acct);
    }

    function renounceRole(
        Roles storage self,
        bytes32 role,
        uint40 originator
    ) internal returns (bool) {
        return _removeRole(self, role, originator);
    }

    function abandonRole(
        Roles storage self,
        bytes32 role,
        uint40 originator
    ) internal returns (bool) {
        if (role == KEEPERS) return false;
        else
            require(
                originator == self.managers[0] ||
                    originator == roleAdmin(self, role),
                "originator not owner or roleAdmin"
            );

        delete self.roles[role];

        return true;
    }

    // very important API for role admin setting, which shall be only exposed to AccessControl func.
    function setRoleAdmin(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal returns (bool) {
        if (role == KEEPERS)
            require(originator == self.managers[1], "originator not bookeeper");
        else require(originator == self.managers[0], "originator not owner");

        // require(acct > 0, "zero acct");
        // require(roleAdmin(self, role) == 0, "already set role admin");

        self.roles[role].admin = acct;
        return true;
    }

    function _removeRole(
        Roles storage self,
        bytes32 role,
        uint40 acct
    ) private returns (bool) {
        delete self.roles[role].isMember[acct];
        return false;
    }

    function copyRoleTo(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        Roles storage to
    ) internal returns (bool) {
        if (role == KEEPERS)
            require(originator == self.managers[1], "originator not bookeeper");
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
