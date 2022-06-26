/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/EnumerableSet.sol";

library Checkpoints {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Checkpoint {
        uint32 _blockNumber;
        uint112 _par;
        uint112 _paid;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    // ======== stacks ========

    struct Delta {
        bool _in;
        uint248 _acct;
    }

    struct Evolution {
        mapping(uint256 => Delta[]) _stacks;
        EnumerableSet.UintSet _blocks;
    }

    //##################
    //##    写接口    ##
    //##################

    function push(
        History storage self,
        uint256 par,
        uint256 paid
    ) internal returns (uint256) {
        uint256 pos = self._checkpoints.length;
        // (uint256 oldPar, uint256 oldPaid) = latest(self);
        if (
            pos > 0 && self._checkpoints[pos - 1]._blockNumber == block.number
        ) {
            self._checkpoints[pos - 1]._par = uint112(par);
            self._checkpoints[pos - 1]._paid = uint112(paid);
        } else {
            self._checkpoints.push(
                Checkpoint({
                    _blockNumber: uint32(block.number),
                    _par: uint112(par),
                    _paid: uint112(paid)
                })
            );
        }
        return (self._checkpoints[self._checkpoints.length - 1]._blockNumber);
    }

    function push(
        Evolution storage self,
        bool join,
        uint40 acct
    ) internal {
        self._stacks[block.number].push(
            Delta({_in: join, _acct: uint248(acct)})
        );

        self._blocks.add(block.number);
    }

    //##################
    //##    读接口    ##
    //##################

    function latest(History storage self)
        internal
        view
        returns (uint256 par, uint256 paid)
    {
        uint256 pos = self._checkpoints.length;
        par = pos == 0 ? 0 : self._checkpoints[pos - 1]._par;
        paid = pos == 0 ? 0 : self._checkpoints[pos - 1]._paid;
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtBlock(History storage self, uint256 blockNumber)
        internal
        view
        returns (uint256 par, uint256 paid)
    {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self._checkpoints[mid]._blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        par = high == 0 ? 0 : self._checkpoints[high - 1]._par;
        paid = high == 0 ? 0 : self._checkpoints[high - 1]._paid;
    }

    function _removeByValue(uint40[] storage input, uint40 value) private {
        uint256 len = input.length;
        while (len > 0) {
            if (input[len - 1] == value) {
                input[len - 1] = input[input.length - 1];
                break;
            }
            len--;
        }
        input.length--;
    }

    function getAtBlock(
        Evolution storage self,
        uint256 blockNumber,
        uint40[] input
    ) internal view returns (uint40[]) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._blocks.length();
        uint256 low = 0;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self._blocks.at(mid) > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        low = high;
        high = self._blocks.length();

        uint40[] storage output;

        uint256 len = input.length;

        while (len > 0) {
            output.push(input[len - 1]);
            len--;
        }

        while (high > low) {
            Delta[] memory deltas = self._stacks[high - 1];
            high--;

            len = deltas.length;

            while (len > 0) {
                if (deltas[len - 1]._in)
                    _removeByValue(output, (uint40(deltas[len - 1]._acct)));
                else output.push(uint40(deltas[len - 1]._acct));
                len--;
            }
        }

        return output;
    }
}
