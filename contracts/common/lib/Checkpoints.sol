/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/lib/EnumerableSet.sol";

library Checkpoints {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Checkpoint {
        uint64 _blockNumber;
        uint64 _par;
        uint64 _paid;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    //##################
    //##    写接口    ##
    //##################

    function push(
        History storage self,
        uint64 par,
        uint64 paid
    ) internal returns (uint64) {
        uint256 pos = self._checkpoints.length;
        if (
            pos > 0 &&
            self._checkpoints[pos - 1]._blockNumber == uint32(block.number)
        ) {
            self._checkpoints[pos - 1]._par = uint64(par);
            self._checkpoints[pos - 1]._paid = uint64(paid);
        } else {
            self._checkpoints.push(
                Checkpoint({
                    _blockNumber: uint32(block.number),
                    _par: uint64(par),
                    _paid: uint64(paid)
                })
            );
        }
        return (self._checkpoints[self._checkpoints.length - 1]._blockNumber);
    }

    //##################
    //##    读接口    ##
    //##################

    function latest(History storage self)
        internal
        view
        returns (uint64 par, uint64 paid)
    {
        uint256 pos = self._checkpoints.length;
        par = pos == 0 ? 0 : self._checkpoints[pos - 1]._par;
        paid = pos == 0 ? 0 : self._checkpoints[pos - 1]._paid;
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtBlock(History storage self, uint64 blockNumber)
        internal
        view
        returns (uint64 par, uint64 paid)
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
}
