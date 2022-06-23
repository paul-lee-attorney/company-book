/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

library Checkpoints {
    struct Checkpoint {
        uint32 _blockNumber;
        uint112 _par;
        uint112 _paid;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

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

    function push(
        History storage self,
        uint256 par,
        uint256 paid
    ) internal returns (uint256) {
        uint256 pos = self._checkpoints.length;
        (uint256 oldPar, uint256 oldPaid) = latest(self);
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

    // function push(
    //     History storage self,
    //     function(uint256, uint256) view returns (uint256) op,
    //     uint256 delta
    // ) internal returns (uint256, uint256) {
    //     return push(self, op(latest(self), delta));
    // }
}
