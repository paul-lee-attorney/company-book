/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./EnumerableSet.sol";

library Checkpoints {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Checkpoint {
        uint64 blockNumber;
        uint64 par;
        uint64 paid;
    }

    struct History {
        Checkpoint[] checkpoints;
    }

    //##################
    //##    写接口    ##
    //##################

    function push(
        History storage self,
        uint64 par,
        uint64 paid
    ) internal returns (uint64) {
        uint256 pos = self.checkpoints.length;
        if (
            pos > 0 &&
            self.checkpoints[pos - 1].blockNumber == uint64(block.number)
        ) {
            self.checkpoints[pos - 1].par = par;
            self.checkpoints[pos - 1].paid = paid;
        } else {
            self.checkpoints.push(
                Checkpoint({
                    blockNumber: uint64(block.number),
                    par: par,
                    paid: paid
                })
            );
        }
        return (self.checkpoints[self.checkpoints.length - 1].blockNumber);
    }

    //##################
    //##    读接口    ##
    //##################

    function latest(History storage self)
        internal
        view
        returns (uint64 par, uint64 paid)
    {
        uint256 pos = self.checkpoints.length;
        par = pos == 0 ? 0 : self.checkpoints[pos - 1].par;
        paid = pos == 0 ? 0 : self.checkpoints[pos - 1].paid;
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtBlock(History storage self, uint64 blockNumber)
        internal
        view
        returns (uint64 par, uint64 paid)
    {
        require(
            blockNumber <= block.number,
            "Checkpoints: block not yet mined"
        );

        uint256 high = self.checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self.checkpoints[mid].blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        par = high == 0 ? 0 : self.checkpoints[high - 1].par;
        paid = high == 0 ? 0 : self.checkpoints[high - 1].paid;
    }
}
