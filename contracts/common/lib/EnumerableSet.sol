// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.4.24;

import "./SNParser.sol";

library EnumerableSet {
    using SNParser for bytes32;

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            delete set._values[lastIndex];
            set._values.length--;

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    //======== Bytes32Set ========

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    //======== AddressSet ========

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    //======== UintSet ========

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[]) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // =========================================================================

    /**
     * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
     * All Rights Reserved.
     ***/

    // shall be checked at front-end so as to avoid overflow
    function valuesToUint8(UintSet storage set)
        internal
        view
        returns (uint8[])
    {
        bytes32[] memory store = _values(set._inner);
        uint8[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // shall be checked at front-end so as to avoid overflow
    function valuesToUint16(UintSet storage set)
        internal
        view
        returns (uint16[])
    {
        bytes32[] memory store = _values(set._inner);
        uint16[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // shall be checked at front-end so as to avoid overflow
    function valuesToUint40(UintSet storage set)
        internal
        view
        returns (uint40[])
    {
        bytes32[] memory store = _values(set._inner);
        uint40[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    function emptyItems(UintSet storage set) internal {
        uint256 len = set._inner._values.length;

        while (len > 0) {
            _remove(set._inner, set._inner._values[len - 1]);
            len--;
        }
    }

    //======== SNList ========

    struct SNList {
        mapping(bytes6 => bytes32) shortToSN;
        Set _inner;
    }

    function add(SNList storage list, bytes32 value) internal returns (bool) {
        list.shortToSN[value.short()] = value;
        return _add(list._inner, value);
    }

    function remove(SNList storage list, bytes32 value)
        internal
        returns (bool)
    {
        delete list.shortToSN[value.short()];
        return _remove(list._inner, value);
    }

    function contains(SNList storage list, bytes6 ssn)
        internal
        view
        returns (bool)
    {
        bytes32 value = list.shortToSN[ssn];
        return _contains(list._inner, value);
    }

    function length(SNList storage list) internal view returns (uint256) {
        return _length(list._inner);
    }

    function at(SNList storage list, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(list._inner, index);
    }

    function values(SNList storage list)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(list._inner);
    }

    // ======== VoterGroup ========

    struct VoterGroup {
        mapping(uint256 => uint256) sigDate;
        mapping(uint256 => bytes32) sigHash;
        mapping(uint256 => uint256) amtOfVoter;
        uint256 sumOfAmt;
        uint256[] voters;
    }

    function add(
        VoterGroup storage group,
        uint256 acct,
        uint256 amount,
        uint256 sigDate,
        bytes32 sigHash
    ) internal returns (bool flag) {
        if (group.sigDate[acct] == 0) {
            group.sigDate[acct] = sigDate;
            group.sigHash[acct] = sigHash;
            group.amtOfVoter[acct] = amount;
            group.sumOfAmt += amount;
            group.voters.push(acct);
            flag = true;
        }
    }

    // ======== SignerGroup ========

    struct Signature {
        uint16 dealSN;
        uint32 blockNumber;
        uint32 sigDate;
        bytes32 sigHash;
    }

    struct SignerGroup {
        // acct => sigSN => sig
        mapping(uint256 => mapping(uint256 => Signature)) signatures;
        // acct => dealSN => sigSN
        mapping(uint256 => mapping(uint256 => uint256)) dealToSN;
        mapping(uint256 => uint256) counterOfSig;
        mapping(uint256 => uint256) counterOfBlank;
        uint256 balance;
        UintSet parties;
    }

    function addBlank(
        SignerGroup storage group,
        uint256 acct,
        uint256 snOfDeal
    ) internal returns (bool flag) {
        if (group.dealToSN[acct][snOfDeal] == 0) {
            add(group.parties, acct);

            group.counterOfBlank[acct]++;
            uint256 sn = group.counterOfBlank[acct];

            group.dealToSN[acct][snOfDeal] = sn;
            group.signatures[acct][sn].dealSN = uint16(snOfDeal);

            group.balance++;

            flag = true;
        }
    }

    function removeParty(SignerGroup storage group, uint256 acct)
        internal
        returns (bool flag)
    {
        uint256 len = group.counterOfBlank[acct];

        if (len > 0 && group.counterOfSig[acct] == 0) {
            group.balance -= len;

            while (len > 0) {
                uint256 snOfDeal = uint256(
                    group.signatures[acct][len - 1].dealSN
                );
                delete group.dealToSN[acct][snOfDeal];
                delete group.signatures[acct][len - 1];
                len--;
            }

            delete group.counterOfBlank[acct];

            remove(group.parties, acct);

            flag = true;
        }
    }

    function signDeal(
        SignerGroup storage group,
        uint40 acct,
        uint16 snOfDeal,
        bytes32 sigHash
    ) internal returns (bool flag) {
        uint256 sn = group.dealToSN[acct][snOfDeal];

        if (sn > 0 && group.signatures[acct][sn].sigDate == 0) {
            Signature storage sig = group.signatures[acct][sn];

            sig.blockNumber = uint32(block.number);
            sig.sigDate = uint32(block.timestamp);
            sig.sigHash = sigHash;

            if (snOfDeal == 0) {
                Signature storage docSig = group.signatures[acct][0];
                docSig.blockNumber = uint32(block.number);
                docSig.sigDate = uint32(block.timestamp);
                docSig.sigHash = sigHash;
            }

            group.counterOfSig[acct]++;
            group.balance--;

            flag = true;
        }
    }
}
