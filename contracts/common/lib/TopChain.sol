/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

library TopChain {
    struct Node {
        uint40 acct;
        uint16 group;
        uint8 deep;
        uint16 prev;
        uint16 next;
        uint16 up;
        uint16 down;
        uint64 amt;
        uint64 sum;
    }

    struct Chain {
        Node[] nodes;
    }

    /* Node[0] {
        acct: (counterOfShares);
        group: counterOfGroups;
        deep: (maxQtyOfMembers);
        prev: tail;
        next: head;
        up: lenOfChain;
        down: (counterOfClasses);
        amt: (null);
        sum: totalVotes;
    } */

    //##################
    //##    写接口    ##
    //##################

    function init(Chain storage chain) internal returns (bool flag) {
        if (chain.nodes.length == 0) {
            chain.nodes.length++;
            flag = true;
        }
    }

    function addNode(Chain storage chain, uint40 acct)
        internal
        returns (uint16 len)
    {
        len = uint16(chain.nodes.length);
        chain.nodes.length++;
        chain.nodes[len].acct = acct;
        chain.nodes[len].deep = 1;
    }

    function delNode(Chain storage chain, uint16 index) internal {
        uint16 len = uint16(chain.nodes.length - 1);

        if (index != len) {
            copyNode(chain, len, index);
        }

        delete chain.nodes[len];
    }

    function copyNode(
        Chain storage chain,
        uint16 from,
        uint16 to
    ) internal {
        Node storage f = chain.nodes[from];
        Node storage t = chain.nodes[to];

        t.acct = f.acct;

        t.amt = f.amt;
        t.sum = f.sum;

        // ---- link members chain ----
        uint16 prev = f.prev;
        uint16 next = f.next;
        uint16 up = f.up;
        uint16 down = f.down;

        t.prev = prev;
        t.next = next;
        t.up = up;
        t.down = down;

        if (prev > 0) chain.nodes[prev].next = to;
        else if (chain.nodes[0].next == from) chain.nodes[0].next = to;

        if (next > 0) chain.nodes[next].prev = to;
        else if (chain.nodes[0].prev == from) chain.nodes[0].prev = to;

        if (up > 0) chain.nodes[up].down = to;

        if (down > 0) chain.nodes[down].up = to;
    }

    // ==== CarveOut ====

    function vCarveOut(Chain storage chain, uint256 index) internal {
        Node storage n = chain.nodes[index];

        uint16 up = n.up;
        uint16 down = n.down;
        uint16 prev = n.prev;
        uint16 next = n.next;

        uint16 top;

        if (up > 0) {
            top = updateSumOfLeader(chain, n.amt, up, true);
            chain.nodes[top].deep--;

            chain.nodes[up].down = down;

            n.up = 0;
        } else if (down == 0) {
            hCarveOut(chain, index);
        }

        if (down > 0) {
            Node storage d = chain.nodes[down];

            if (up == 0) {
                top = down;

                if (prev > 0) {
                    d.prev = prev;
                    chain.nodes[prev].next = down;

                    n.prev = 0;
                } else chain.nodes[0].next = down;

                if (next > 0) {
                    d.next = next;
                    chain.nodes[next].prev = down;

                    n.next = 0;
                } else chain.nodes[0].prev = down;

                d.sum = (n.sum - n.amt);
                n.sum = n.amt;

                d.deep = n.deep - 1;
                n.deep = 1;
            }

            d.up = up;
            n.down = 0;
        }
        if (top > 0) {
            hMove(chain, top, true);
        }

        n.group = 0;
    }

    function hCarveOut(Chain storage chain, uint256 index) internal {
        Node storage n = chain.nodes[index];

        uint16 prev = n.prev;
        uint16 next = n.next;

        chain.nodes[prev].next = next;
        n.prev = 0;

        chain.nodes[next].prev = prev;
        n.next = 0;

        _decreaseLenOfChain(chain);
    }

    // ==== Insert ====

    function vInsert(
        Chain storage chain,
        uint16 index,
        uint16 up,
        uint16 down
    ) internal returns (uint16 top) {
        Node storage n = chain.nodes[index];

        if (up > 0) {
            Node storage u = chain.nodes[up];

            u.down = index;
            n.up = up;

            top = updateSumOfLeader(chain, n.amt, up, false);
            chain.nodes[top].deep++;

            n.group = u.group;
        } else {
            require(down > 0, "MC._vInsert: zero down & up");

            Node storage d = chain.nodes[down];

            uint16 prev = d.prev;
            uint16 next = d.next;

            n.prev = prev;
            d.prev = 0;
            chain.nodes[prev].next = index;

            n.next = next;
            d.next = 0;
            chain.nodes[next].prev = index;

            n.sum += d.sum;
            d.sum = d.amt;

            n.deep = d.deep + 1;
            d.deep = 1;

            top = index;

            // if (d.group == 0) {
            //     d.group = chain.nodes[0].group++;
            //     setZeroDeep(chain, zeroDeep(chain) + 1);
            // }
            n.group = d.group;
        }

        if (down > 0) {
            chain.nodes[down].up = index;
            n.down = down;
        }

        hMove(chain, top, false);
    }

    function hInsert(
        Chain storage chain,
        uint16 index,
        uint16 prev,
        uint16 next
    ) internal {
        Node storage n = chain.nodes[index];

        chain.nodes[prev].next = index;
        n.prev = prev;

        chain.nodes[next].prev = index;
        n.next = next;

        _increaseLenOfChain(chain);
    }

    // ==== Move ====

    function vMove(
        Chain storage chain,
        uint16 index,
        bool decrease
    ) internal {
        Node storage n = chain.nodes[index];

        (uint16 up, uint16 down) = getVPos(
            chain,
            n.amt,
            n.up,
            n.down,
            decrease
        );

        uint16 top;
        if (up != n.up && down != n.down) {
            vCarveOut(chain, index);
            top = vInsert(chain, index, up, down);
        } else top = topOfBranch(chain, index);

        hMove(chain, top, decrease);
    }

    function hMove(
        Chain storage chain,
        uint16 index,
        bool decrease
    ) private {
        Node storage n = chain.nodes[index];

        (uint16 prev, uint16 next) = getHPos(
            chain,
            n.sum,
            n.prev,
            n.next,
            decrease
        );

        if (next != n.next && prev != n.prev) {
            hCarveOut(chain, index);
            hInsert(chain, index, prev, next);
        }
    }

    // ==== ChangeAmt ====

    function changeAmt(
        Chain storage chain,
        uint16 index,
        uint64 deltaAmt,
        bool decrease
    ) internal {
        Node storage n = chain.nodes[index];

        if (decrease) {
            n.amt -= deltaAmt;
            n.sum -= deltaAmt;

            chain.nodes[0].sum -= deltaAmt;
        } else {
            n.amt += deltaAmt;
            n.sum += deltaAmt;

            chain.nodes[0].sum += deltaAmt;

            if (n.prev == 0 && n.next == 0) n.prev = chain.nodes[0].prev;
        }

        if (n.amt > 0) {
            if (n.group > 0) {
                updateSumOfLeader(chain, deltaAmt, index, decrease);
                vMove(chain, index, decrease);
            } else {
                hMove(chain, index, decrease);
            }
        } else {
            if (n.group > 0) vCarveOut(chain, index);
            else hCarveOut(chain, index);
        }
    }

    // ======== group tool ========

    function updateSumOfLeader(
        Chain storage chain,
        uint64 amt,
        uint16 index,
        bool decrease
    ) internal returns (uint16 top) {
        top = topOfBranch(chain, index);

        if (decrease) chain.nodes[top].sum -= amt;
        else chain.nodes[top].sum += amt;
    }

    // ==== restoreChain ====

    function restoreChain(Chain storage chain, Node[] memory snapshot)
        internal
    {
        uint256 len = snapshot.length;
        chain.nodes.length = 0;
        uint256 i = 0;

        while (i < len) {
            chain.nodes.length++;
            chain.nodes[i] = snapshot[i];
            i++;
        }
    }

    // ==== zero node ====

    function increaseZeroAcct(Chain storage chain) internal {
        chain.nodes[0].acct++;
    }

    function increaseCounterOfGroups(Chain storage chain) internal {
        chain.nodes[0].group++;
    }

    function setZeroDeep(Chain storage chain, uint8 amt) internal {
        chain.nodes[0].deep = amt;
    }

    function _increaseLenOfChain(Chain storage chain) private {
        chain.nodes[0].up++;
    }

    function _decreaseLenOfChain(Chain storage chain) private {
        chain.nodes[0].up--;
    }

    function increaseZeroDown(Chain storage chain) internal {
        chain.nodes[0].down++;
    }

    function decreaseZeroDown(Chain storage chain) internal {
        chain.nodes[0].down--;
    }

    function setZeroAmt(Chain storage chain, uint64 amt) internal {
        chain.nodes[0].amt = amt;
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Zero Node ====

    function zeroAcct(Chain storage chain) internal view returns (uint40) {
        return chain.nodes[0].acct;
    }

    function counterOfGroups(Chain storage chain)
        internal
        view
        returns (uint16)
    {
        return chain.nodes[0].group;
    }

    function zeroDeep(Chain storage chain) internal view returns (uint8) {
        return chain.nodes[0].deep;
    }

    function tail(Chain storage chain) internal view returns (uint16) {
        return chain.nodes[0].prev;
    }

    function head(Chain storage chain) internal view returns (uint16) {
        return chain.nodes[0].next;
    }

    function lenOfChain(Chain storage chain) internal view returns (uint16) {
        return chain.nodes[0].up;
    }

    function zeroDown(Chain storage chain) internal view returns (uint16) {
        return chain.nodes[0].down;
    }

    function zeroAmt(Chain storage chain) internal view returns (uint64) {
        return chain.nodes[0].amt;
    }

    function totalVotes(Chain storage chain) internal view returns (uint64) {
        return chain.nodes[0].sum;
    }

    // ==== locate position ====
    function getNode(Chain storage chain, uint16 index)
        internal
        view
        returns (
            uint40 acct,
            uint16 group,
            uint8 deep,
            uint16 prev,
            uint16 next,
            uint16 up,
            uint16 down,
            uint64 amt,
            uint64 sum
        )
    {
        Node storage n = chain.nodes[index];

        acct = n.acct;
        group = n.group;
        deep = n.deep;
        prev = n.prev;
        next = n.next;
        up = n.up;
        down = n.down;
        amt = n.amt;
        sum = n.sum;
    }

    function getHPos(
        Chain storage chain,
        uint64 amount,
        uint16 prev,
        uint16 next,
        bool decrease
    ) internal view returns (uint16, uint16) {
        if (decrease)
            while (chain.nodes[next].sum > amount) {
                prev = next;
                next = chain.nodes[next].next;
                if (next == 0) break;
            }
        else
            while (chain.nodes[prev].sum < amount) {
                next = prev;
                prev = chain.nodes[prev].prev;
                if (prev == 0) break;
            }

        return (prev, next);
    }

    function getVPos(
        Chain storage chain,
        uint64 amount,
        uint16 up,
        uint16 down,
        bool decrease
    ) internal view returns (uint16, uint16) {
        if (decrease)
            while (chain.nodes[down].amt > amount) {
                up = down;
                down = chain.nodes[down].down;
                if (down == 0) break;
            }
        else
            while (chain.nodes[up].amt < amount) {
                down = up;
                up = chain.nodes[up].up;
                if (up == 0) break;
            }

        return (up, down);
    }

    // ==== group ====

    function groupNo(Chain storage chain, uint16 index)
        internal
        view
        returns (uint16)
    {
        return chain.nodes[index].group;
    }

    function topOfBranch(Chain storage chain, uint16 group)
        internal
        view
        returns (uint16 next)
    {
        next = chain.nodes[0].next;
        while (next > 0) {
            if (chain.nodes[next].group == group) {
                break;
            }
            next = chain.nodes[next].next;
        }
    }

    function leaderOfGroup(Chain storage chain, uint16 group)
        internal
        view
        returns (uint40)
    {
        uint16 top = topOfBranch(chain, group);
        return chain.nodes[top].acct;
    }

    function deepOfBranch(Chain storage chain, uint16 top)
        internal
        view
        returns (uint8)
    {
        return chain.nodes[top].deep;
    }

    function votesOfGroup(Chain storage chain, uint16 group)
        internal
        view
        returns (uint64)
    {
        uint16 top = topOfBranch(chain, group);
        return chain.nodes[top].sum;
    }

    function membersOfGroup(Chain storage chain, uint16 group)
        internal
        view
        returns (uint40[] memory)
    {
        uint16 top = topOfBranch(chain, group);
        uint256 len = chain.nodes[top].deep;
        uint40[] memory list = new uint40[](len);

        uint256 j = 0;
        while (j < len) {
            list[j] = chain.nodes[top].acct;
            top = chain.nodes[top].down;
            j++;
        }

        return list;
    }

    function affiliated(
        Chain storage chain,
        uint16 index1,
        uint16 index2
    ) internal view returns (bool) {
        return chain.nodes[index1].group == chain.nodes[index2].group;
    }

    // ==== members ====
    function membersList(Chain storage chain)
        internal
        view
        returns (uint40[] memory)
    {
        uint256 len = chain.nodes.length - 1;
        uint40[] memory list = new uint40[](len);

        while (len > 0) {
            list[len - 1] = chain.nodes[len].acct;
            len--;
        }

        return list;
    }

    // ==== backup ====

    function getSnapshot(Chain storage chain)
        internal
        view
        returns (Node[] memory)
    {
        return chain.nodes;
    }
}
