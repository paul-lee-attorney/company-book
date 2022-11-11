// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// pragma experimental ABIEncoderV2;

library TopChain {
    struct Node {
        uint40 acct;
        uint16 group;
        uint16 deep;
        uint40 prev;
        uint40 next;
        uint40 up;
        uint40 down;
        uint64 amt;
        uint64 sum;
    }

    struct Chain {
        mapping(uint256 => Node) nodes;
    }

    /* Node[0] {
        acct: basedOnPar;
        group: counterOfGroups;
        deep: maxQtyOfMembers;
        prev: tail;
        next: head;
        up: qtyOfMembers;
        down: null;
        amt: lenOfChain;
        sum: totalVotes;
    } */

    //##################
    //##    写接口    ##
    //##################

    function setVoteBase(Chain storage chain, bool onPar)
        internal
        returns (bool flag)
    {
        if (onPar != basedOnPar(chain)) {
            chain.nodes[0].acct = onPar ? 1 : 0;
            flag = true;
        }
    }

    // ==== restoreChain ====

    function restoreChain(Chain storage chain, Node[] memory snapshot)
        internal
    {
        uint256 len = snapshot.length - 1;

        while (len > 0) {
            chain.nodes[snapshot[len].acct] = snapshot[len];
            len--;
        }

        chain.nodes[0] = snapshot[0];
    }

    // ==== Node ====

    function addNode(Chain storage chain, uint40 acct)
        internal
        returns (bool flag)
    {
        Node storage n = chain.nodes[acct];

        if (acct > 0 && n.acct == 0) {
            n.acct = acct;
            n.deep = 1;

            _increaseQtyOfMembers(chain);

            flag = true;
        }
    }

    function delNode(Chain storage chain, uint40 acct)
        internal
        returns (bool flag)
    {
        if (isMember(chain, acct)) {
            delete chain.nodes[acct];

            _decreaseQtyOfMembers(chain);

            flag = true;
        }
    }

    // ==== CarveOut ====

    function vCarveOut(Chain storage chain, uint40 acct)
        internal
        returns (bool flag)
    {
        if (isMember(chain, acct)) {
            Node storage n = chain.nodes[acct];

            uint40 up = n.up;
            uint40 down = n.down;
            uint40 prev = n.prev;
            uint40 next = n.next;

            uint40 top;

            if (up > 0) {
                top = updateSumOfLeader(chain, n.amt, up, true);
                chain.nodes[top].deep--;

                chain.nodes[up].down = down;

                n.up = 0;
            } else if (down == 0) {
                hCarveOut(chain, acct);
            }

            if (down > 0) {
                Node storage d = chain.nodes[down];

                if (up == 0) {
                    top = down;

                    d.prev = prev;
                    chain.nodes[prev].next = down;
                    n.prev = 0;

                    d.next = next;
                    chain.nodes[next].prev = down;
                    n.next = 0;

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

            flag = true;
        }
    }

    function hCarveOut(Chain storage chain, uint40 acct)
        internal
        returns (bool flag)
    {
        if (isMember(chain, acct)) {
            Node storage n = chain.nodes[acct];

            chain.nodes[n.prev].next = n.next;
            chain.nodes[n.next].prev = n.prev;

            n.prev = 0;
            n.next = 0;

            _decreaseLenOfChain(chain);

            flag = true;
        }
    }

    // ==== Insert ====

    function vInsert(
        Chain storage chain,
        uint40 acct,
        uint40 up,
        uint40 down
    ) internal returns (uint40 top) {
        Node storage n = chain.nodes[acct];

        if (up > 0) {
            Node storage u = chain.nodes[up];

            u.down = acct;
            n.up = up;

            top = updateSumOfLeader(chain, n.amt, up, false);
            chain.nodes[top].deep++;

            n.group = u.group;
        } else {
            require(down > 0, "MC._vInsert: zero down & up");

            Node storage d = chain.nodes[down];

            uint40 prev = d.prev;
            uint40 next = d.next;

            n.prev = prev;
            d.prev = 0;
            chain.nodes[prev].next = acct;

            n.next = next;
            d.next = 0;
            chain.nodes[next].prev = acct;

            n.sum += d.sum;
            d.sum = d.amt;

            n.deep = d.deep + 1;
            d.deep = 1;

            top = acct;

            n.group = d.group;
        }

        if (down > 0) {
            chain.nodes[down].up = acct;
            n.down = down;
        }

        hMove(chain, top, false);
    }

    function hInsert(
        Chain storage chain,
        uint40 index,
        uint40 prev,
        uint40 next
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
        uint40 acct,
        bool decrease
    ) internal {
        Node storage n = chain.nodes[acct];

        (uint40 up, uint40 down) = getVPos(
            chain,
            n.amt,
            n.up,
            n.down,
            decrease
        );

        uint40 top;
        if (up != n.up && down != n.down) {
            vCarveOut(chain, acct);
            top = vInsert(chain, acct, up, down);
        } else top = topOfBranch(chain, acct);

        hMove(chain, top, decrease);
    }

    function hMove(
        Chain storage chain,
        uint40 acct,
        bool decrease
    ) private {
        Node storage n = chain.nodes[acct];

        (uint40 prev, uint40 next) = getHPos(
            chain,
            n.sum,
            n.prev,
            n.next,
            decrease
        );

        if (next != n.next && prev != n.prev) {
            hCarveOut(chain, acct);
            hInsert(chain, acct, prev, next);
        }
    }

    // ==== ChangeAmt ====

    function changeAmt(
        Chain storage chain,
        uint40 acct,
        uint64 deltaAmt,
        bool decrease
    ) internal {
        Node storage n = chain.nodes[acct];

        if (decrease) {
            n.amt -= deltaAmt;
            n.sum -= deltaAmt;

            _decreaseTotalVotes(chain, deltaAmt);
        } else {
            n.amt += deltaAmt;
            n.sum += deltaAmt;

            _increaseTotalVotes(chain, deltaAmt);

            if (n.prev == 0 && n.next == 0) n.prev = chain.nodes[0].prev;
        }

        if (n.amt > 0) {
            if (n.group > 0) {
                updateSumOfLeader(chain, deltaAmt, acct, decrease);
                vMove(chain, acct, decrease);
            } else {
                hMove(chain, acct, decrease);
            }
        } else {
            if (n.group > 0) vCarveOut(chain, acct);
            else hCarveOut(chain, acct);
        }
    }

    // ======== group tool ========

    function updateSumOfLeader(
        Chain storage chain,
        uint64 amt,
        uint40 acct,
        bool decrease
    ) internal returns (uint40 top) {
        top = topOfBranch(chain, acct);

        if (decrease) chain.nodes[top].sum -= amt;
        else chain.nodes[top].sum += amt;
    }

    // ==== zero node ====

    function increaseCounterOfShares(Chain storage chain) internal {
        chain.nodes[0].acct++;
    }

    function increaseCounterOfGroups(Chain storage chain) internal {
        chain.nodes[0].group++;
    }

    function setMaxQtyOfMembers(Chain storage chain, uint16 amt) internal {
        chain.nodes[0].deep = amt;
    }

    function _increaseQtyOfMembers(Chain storage chain) private {
        chain.nodes[0].up++;
    }

    function _decreaseQtyOfMembers(Chain storage chain) private {
        chain.nodes[0].up--;
    }

    function increaseCounterOfClasses(Chain storage chain) internal {
        chain.nodes[0].down++;
    }

    function _increaseLenOfChain(Chain storage chain) private {
        chain.nodes[0].amt++;
    }

    function _decreaseLenOfChain(Chain storage chain) private {
        chain.nodes[0].amt--;
    }

    function _increaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum += deltaAmt;
    }

    function _decreaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum -= deltaAmt;
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Zero Node ====

    function basedOnPar(Chain storage chain) internal view returns (bool) {
        return chain.nodes[0].acct == 1;
    }

    function counterOfShares(Chain storage chain)
        internal
        view
        returns (uint32)
    {
        return uint32(chain.nodes[0].acct);
    }

    function counterOfGroups(Chain storage chain)
        internal
        view
        returns (uint16)
    {
        return chain.nodes[0].group;
    }

    function maxQtyOfMembers(Chain storage chain)
        internal
        view
        returns (uint16)
    {
        return chain.nodes[0].deep;
    }

    function tail(Chain storage chain) internal view returns (uint40) {
        return chain.nodes[0].prev;
    }

    function head(Chain storage chain) internal view returns (uint40) {
        return chain.nodes[0].next;
    }

    function qtyOfMembers(Chain storage chain) internal view returns (uint40) {
        return chain.nodes[0].up;
    }

    function counterOfClasses(Chain storage chain)
        internal
        view
        returns (uint16)
    {
        return uint16(chain.nodes[0].down);
    }

    function lenOfChain(Chain storage chain) internal view returns (uint64) {
        return chain.nodes[0].amt;
    }

    function totalVotes(Chain storage chain) internal view returns (uint64) {
        return chain.nodes[0].sum;
    }

    // ==== locate position ====

    function getNode(Chain storage chain, uint40 acct)
        internal
        view
        returns (
            uint16 group,
            uint16 deep,
            uint40 prev,
            uint40 next,
            uint40 up,
            uint40 down,
            uint64 amt,
            uint64 sum
        )
    {
        if (isMember(chain, acct)) {
            Node storage n = chain.nodes[acct];

            group = n.group;
            deep = n.deep;
            prev = n.prev;
            next = n.next;
            up = n.up;
            down = n.down;
            amt = n.amt;
            sum = n.sum;
        } else revert("TC.getNode: acct is not a member");
    }

    function getHPos(
        Chain storage chain,
        uint64 amount,
        uint40 prev,
        uint40 next,
        bool decrease
    ) internal view returns (uint40, uint40) {
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
        uint40 up,
        uint40 down,
        bool decrease
    ) internal view returns (uint40, uint40) {
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

    function nextNode(Chain storage chain, uint40 acct)
        internal
        view
        returns (uint40 next)
    {
        Node storage n = chain.nodes[acct];

        if (n.down > 0) next = n.down;
        else if (n.next > 0) next = n.next;
        else if (n.up > 0) {
            next = topOfBranch(chain, acct);
            next = chain.nodes[next].next;
        }
    }

    // ==== group ====

    function groupNo(Chain storage chain, uint40 acct)
        internal
        view
        returns (uint16 group)
    {
        if (isMember(chain, acct)) group = chain.nodes[acct].group;
        else revert("TC.groupNo: acct is not a member");
    }

    function topOfBranch(Chain storage chain, uint40 acct)
        internal
        view
        returns (uint40 top)
    {
        while (acct > 0) {
            top = acct;
            acct = chain.nodes[top].up;
        }
    }

    function leaderOfGroup(Chain storage chain, uint16 group)
        internal
        view
        returns (uint40 next)
    {
        next = chain.nodes[0].next;
        while (next > 0) {
            if (chain.nodes[next].group == group) {
                break;
            }
            next = chain.nodes[next].next;
        }
    }

    function deepOfBranch(Chain storage chain, uint40 top)
        internal
        view
        returns (uint16)
    {
        if (top > 0 && chain.nodes[top].acct == top)
            return chain.nodes[top].deep;
        else revert("TC.deepOfBranch: top is not a member");
    }

    function votesOfGroup(Chain storage chain, uint16 group)
        internal
        view
        returns (uint64)
    {
        uint40 top = leaderOfGroup(chain, group);
        return chain.nodes[top].sum;
    }

    function membersOfGroup(Chain storage chain, uint16 group)
        internal
        view
        returns (uint40[] memory)
    {
        uint40 top = leaderOfGroup(chain, group);
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
        uint40 acct1,
        uint40 acct2
    ) internal view returns (bool) {
        if (
            acct1 > 0 &&
            chain.nodes[acct1].acct == acct1 &&
            acct2 > 0 &&
            chain.nodes[acct2].acct == acct2
        ) return chain.nodes[acct1].group == chain.nodes[acct2].group;
        else revert("TC.affiliated: not all accts are members");
    }

    // ==== members ====
    function isMember(Chain storage chain, uint40 acct)
        internal
        view
        returns (bool)
    {
        return acct > 0 && chain.nodes[acct].acct == acct;
    }

    function membersList(Chain storage chain)
        internal
        view
        returns (uint40[] memory)
    {
        uint256 len = qtyOfMembers(chain);
        uint40[] memory list = new uint40[](len);

        uint40 cur = chain.nodes[0].next;
        uint256 i = 0;

        while (i < len) {
            list[i] = chain.nodes[cur].acct;

            cur = nextNode(chain, cur);

            i++;
        }

        return list;
    }

    // ==== backup ====

    function getSnapshot(Chain storage chain)
        internal
        view
        returns (Node[] memory)
    {
        uint256 len = qtyOfMembers(chain);

        Node[] memory list = new Node[](len + 1);

        list[0] = chain.nodes[0];

        uint40 cur = chain.nodes[0].next;
        uint256 i = 1;

        while (i <= len) {
            list[i] = chain.nodes[cur];

            cur = nextNode(chain, cur);

            i++;
        }

        return list;
    }
}
