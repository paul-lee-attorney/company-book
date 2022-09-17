/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

import "./Checkpoints.sol";
import "./EnumerableSet.sol";

library MembersChain {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.Bytes32Set
    
    struct Data {
        uint64 amt;
        uint64 sum;
    }

    struct Pos {
        uint16 prev;
        uint16 next;
        uint16 up;
        uint16 down;
    }

    struct Member {
        uint40 acct;
        uint16 group;
        Pos[2] pos;
        Data[2] data;
        EnumerableSet.Bytes32Set sharesInHand;
        Checkpoints.History votesInHand;
    }

    struct Group {
        uint16[2] leader;
    }

    struct GeneralMeeting {
        Member[] members;
        Checkpoints.History qtyOfMembers;
        mapping(uint40 => uint16) indexOf;
        mapping(uint16 => Group) groups;
        uint16 counterOfGroups;
        uint16[2] head;
        uint16[2] tail;
    }

    //##################
    //##    写接口    ##
    //##################

    function addMember(
        GeneralMeeting storage self,
        uint40 acct
    ) internal returns (bool) {
        if (!contains(self, acct)) {
            Member storage m = self.members.push();
            m.acct = acct;
            uint16 len = uint16(self.members.length);
            self.indexOf[acct] = len;
            self.qtyOfMembers.push(len, 1);
            return true;
        } else return false;
    }

    function delMember(GeneralMeeting storage self, uint40 acct) internal returns (bool) {
        uint16 i = self.indexOf[acct];
        if (i == 0 ) return false;

        uint16 len = uint16(self.members.length);

        if (i != len) {
            Member storage last = self.members[len - 1];

            self.indexOf[last.acct] = i;

            member.acct = last.acct;
            member.group = last.group;

            member.data[0].amt = last.data[0].amt;
            member.data[0].sum = last.data[0].sum;

            uint16 prev = last.pos[0].prev;
            uint16 next = last.pos[0].next;
            uint16 up = last.pos[0].up;
            uint16 down = last.pos[0].down;

            if (prev > 0) {
                member.pos[0].prev = prev;
                self.members[prev - 1].pos[0].next = i;
            } else if (self.head[0] == len) self.head[0] = i;

            if (next > 0) {
                member.pos[0].next = next;
                self.members[next - 1].pos[0].prev = i;
            } else if (self.tail[0] == len) self.tail[0] = i;

            if (up > 0) {
                member.pos[0].up = up;
                self.members[up - 1].pos[0].down = i;
            }

            if (down > 0) {
                member.pos[0].down = down;
                self.members[down - 1].pos[0].up = i;
            }

            // ---- par ----

            member.data[1].amt = last.data[1].amt;
            member.data[1].sum = last.data[1].sum;

            prev = last.pos[1].prev;
            next = last.pos[1].next;
            up = last.pos[1].up;
            down = last.pos[1].down;

            if (prev > 0) {
                member.pos[1].prev = prev;
                self.members[prev - 1].pos[1].next = i;
            } else if (self.head[1] == len) self.head[1] = i;

            if (next > 0) {
                member.pos[1].next = next;
                self.members[next - 1].pos[1].prev = i;
            } else if (self.tail[1] == len) self.tail[1] = i;

            if (up > 0) {
                member.pos[1].up = up;
                self.members[up - 1].pos[1].down = i;
            }

            if (down > 0) {
                member.pos[1].down = down;
                self.members[down - 1].pos[1].up = i;
            }
        }

        delete self.indexOf[acct];

        self.members.pop();
        self.qtyOfMembers.push(uint64(self.members.length), 0);

        return true;
    }

    function addShareToMember(GeneralMeeting storage self, uint40 acct, bytes32 shareNumber) internal returns(bool) {
        uint16 i = getIndex(self, acct);
        return self.members[i-1].sharesInHand.add(shareNumber); 
    }

    function removeShareFromMember(GeneralMeeting storage self, uint40 acct, bytes32 shareNumber) internal returns(bool) {
        uint16 i = getIndex(self, acct);
        return self.members[i-1].sharesInHand.remove(shareNumber); 
    }

    function addMemberIntoGroup(
        GeneralMeeting storage self,
        uint40 acct,
        uint16 group
    ) internal returns(bool) {
        uint16 i = getIndex(self, acct);
        Member storage m = self.members[i - 1];

        require(
            m.group == 0,
            "MC.addMemberIntoGroup: member already in a group"
        );

        require(
            group > 0 && group <= self.counterOfGroups + 1,
            "MC.pushMemberIntoGroup: groupNo overflow"
        );

        if (group > self.counterOfGroups) {
            self.counterOfGroups++;

            self.groups[group].leader[0] = acct;
            self.groups[group].leader[1] = acct;

            m.group = group;

            return true;

        } else {            

            // ---- paid ----

            uint40 leader = self.groups[group].leader[0];
            uint16 top;

            if (leader > 0) top = self.indexOf[leader];
            else revert("MC.pushMemberIntoGroup: group not exist");

            m.group = group;

            (uint16 up, uint16 down) = getVPos(self, 0, m.data[0].amt, 0, top, true);

            _hCarveOut(self, m, 0);

            top = _vInsert(self, m, 0, up, down);

            Member storage l = self.members[top - 1];
            _hMove(self, l, 0, false);

            // ---- par ----

            leader = self.groups[group].leader[1];

            if (leader > 0) top = self.indexOf[leader];
            else revert("MC.pushMemberIntoGroup: group not exist");

            (up, down) = getVPos(self, 1, m.data[1].amt, 0, top, true);

            _hCarveOut(self, m, 1);

            top = _vInsert(self, m, 1, up, down);

            l = self.members[top - 1];
            _hMove(self, l, 1, false);

            return true;
        }
    }

    function removeMemberFromGroup(
        GeneralMeeting storage self,
        uint40 acct,
        uint16 group
    ) internal returns (bool) {
        uint16 i = getIndex(self, acct);
        Member storage m = self.members[i - 1];

        require(
            m.group == group,
            "MC.removeMemberFromGroup: member not in the group"
        );

        uint16 top = _vCarveOut(self, m, 0);
        if (top > 0) {
           Member storage l = self.members[top - 1];
            _hMove(self, l, 0, true);
        }

        top = _vCarveOut(self, m, 1);
        if (top > 0) {
            l = self.members[top - 1];
            _hMove(self, l, 1, true);
        }

        m.group = 0;

        return true;
    }

    function changeAmtOfMember(
        GeneralMeeting storage self,
        uint8 basedOnPar,
        uint40 acct,
        uint64 delta,
        bool decrease
    ) internal returns(uint64 blocknumber) {
        uint16 i = getIndex(self, acct);
        Member storage m = self.members[i - 1];

        if (decrease) {
            m.data[basedOnPar].amt -= delta;
            m.data[basedOnPar].sum -= delta;

        } else {
            m.data[basedOnPar].amt += delta;
            m.data[basedOnPar].sum += delta;
        }

        if (m.group > 0) {
           _vMove(self, m, basedOnPar, decrease);
        } else {
            _hMove(self, m, basedOnPar, decrease);
        }

       blocknumber = m.votesInHand.push(m.data[0].amt, m.data[1].amt);
    }

    // ======== basic action ========



    function _updateSumOfUpNodes(
        GeneralMeeting storage self,
        uint8 basedOnPar,
        uint64 amt,
        uint16 up,
        bool addAmt
    ) private returns (uint16 top) {
        if (addAmt)
            while (up > 0) {
                self.members[up - 1].data[basedOnPar].sum += amt;
                top = up;
                up = self.members[up - 1].pos[basedOnPar].up;
            }
        else
            while (up > 0) {
                self.members[up - 1].data[basedOnPar].sum -= amt;
                top = up;
                up = self.members[up - 1].pos[basedOnPar].up;
            }
    }

    function _hCarveOut(GeneralMeeting storage self, Member storage member, uint8 basedOnPar) private {
        uint16 prev = member.pos[basedOnPar].prev;
        uint16 next = member.pos[basedOnPar].next;

        if (prev > 0) {
            member.pos[basedOnPar].prev = 0;
            self.members[prev - 1].pos[basedOnPar].next = next;
        } else self.head[basedOnPar] = next;

        if (next > 0) {
            member.pos[basedOnPar].next = 0;
            self.members[next - 1].pos[basedOnPar].prev = prev;
        } else self.tail[basedOnPar] = prev;
    }

    function _vCarveOut(
        GeneralMeeting storage self,
        Member storage member
        uint8 basedOnPar,
    ) private returns (uint16 top) {
        uint16 up = member.pos[basedOnPar].up;
        uint16 down = member.pos[basedOnPar].down;
        uint16 prev = member.pos[basedOnPar].prev;
        uint16 next = member.pos[basedOnPar].next;

        if (up > 0) {
            top = _updateSumOfUpNodes(
                self,
                basedOnPar,
                member.data[basedOnPar].amt,
                up,
                false
            );
            self.members[up - 1].pos[basedOnPar].down = down;

            member.pos[basedOnPar].up = 0;
        } else if (down == 0) {
            self.groups[member.group].leader[basedOnPar] = 0;
            _hCarveOut(self, member, basedOnPar);
        }

        if (down > 0) {
            if (up == 0) {
                self.groups[member.group].leader[basedOnPar] = down;
                top = down;

                if (prev > 0) {
                    self.members[down - 1].pos[basedOnPar].prev = prev;
                    self.members[prev - 1].pos[basedOnPar].next = down;
                }

                if (next > 0) {
                    self.members[down - 1].pos[basedOnPar].next = next;
                    self.members[next - 1].pos[basedOnPar].prev = down;
                }
            } else self.members[down - 1].pos[basedOnPar].up = up;

            member.pos[basedOnPar].down = 0;
        }

        member.data[basedOnPar].sum = member.amt;
        // member.group = 0;
    }

    function _hInsert(
        GeneralMeeting storage self,
        Member storage member,
        uint8 basedOnPar,
        uint16 prev,
        uint16 next
    ) private {
        uint16 i = getIndex(self, member.acct);

        if (prev > 0) {
            self.members[prev - 1].pos[basedOnPar].next = i;
            member.pos[basedOnPar].prev = prev;
        } else self.head[basedOnPar] = i;

        if (next > 0) {
            self.members[next - 1].pos[basedOnPar].prev = i;
            member.pos[basedOnPar].next = next;
        } else self.tail[basedOnPar] = i;
    }

    function _vInsert(
        GeneralMeeting storage self,
        Member storage member,
        uint8 basedOnPar,
        uint16 up,
        uint16 down
    ) private returns (uint16 top) {
        uint16 i = getIndex(self, member.acct);

        if (up > 0) {
            self.members[up - 1].pos[basedOnPar].down = i;
            member.pos[basedOnPar].up = up;

            top = _updateSumOfUpNodes(self, basedOnPar, member.amt, up, true);
        } else {
            require(down > 0, "MC._vInsert: zero down & up");

            uint16 prev = self.members[down - 1].pos[basedOnPar].prev;
            uint16 next = self.members[down - 1].pos[basedOnPar].next;

            member.pos[basedOnPar].prev = prev;
            self.members[down - 1].pos[basedOnPar].prev = 0;
            self.members[prev - 1].pos[basedOnPar].next = i;

            member.pos[basedOnPar].next = next;
            self.members[down - 1].pos[basedOnPar].next = 0;
            self.members[next - 1].pos[basedOnPar].prev = i;

            self.groups[member.group].leader[basedOnPar] = i;

            top = i;
        }

        if (down > 0) {
            self.members[down - 1].pos[basedOnPar].up = i;
            member.pos[basedOnPar].down = down;

            member.data[basedOnPar].sum += self
                .members[down - 1]
                .data[basedOnPar]
                .sum;
        }
    }

    function _hMove(
        GeneralMeeting storage self,
        Member storage member,
        uint8 basedOnPar,
        bool toRight
    ) private returns (bool) {
        (uint16 prev, uint16 next) = getHPos(
            self,
            basedOnPar,
            member.data[basedOnPar].sum,
            member.pos[basedOnPar].prev,
            member.pos[basedOnPar].next,
            toRight
        );

        if (next != member.pos[basedOnPar].next && prev != member.pos[basedOnPar].prev) {
            _hCarveOut(self, member, basedOnPar);
            _hInsert(self, member, basedOnPar, prev, next);
        }
    }

    function _vMove(
        GeneralMeeting storage self,
        Member storage member,
        uint8 basedOnPar,
        bool toDown
    ) private returns (bool) {
        (uint16 up, uint16 down) = getVPos(
            self,
            basedOnPar,
            member.data[basedOnPar].amt,
            member.pos[basedOnPar].up,
            member.pos[basedOnPar].down,
            toDown
        );

        if (up != member.pos[basedOnPar].up && down != member.pos[basedOnPar].down) {
            _vCarveOut(self, member, basedOnPar);
            uint16 top = _vInsert(self, member, basedOnPar, up, down);

            Member storage leader = self.members[top - 1];
            _hMove(self, leader, basedOnPar, toDown);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function contains(GeneralMeeting storage self, uint40 acct)
        internal
        view
        returns (bool)
    {
        return self.indexOf[acct] > 0;
    }

    function getIndex(GeneralMeeting storage self, uint40 acct)
        internal
        view
        returns (uint16)
    {
        require(contains(self, acct), "MC.getIndex: acct not a member of GeneralMeeting");
        return self.indexOf[acct];
    }

    function groupNo(GeneralMeeting storage self, uint40 acct) internal view returns(uint16) {
        uint16 i = getIndex(self, acct);
        return self.members[i - 1].group;
    }

    function getMember(GeneralMeeting storage self, uint40 acct)
        internal
        view
        returns (
            uint40 acct,
            bool isGroup,
            uint64 amt,
            uint16 prev,
            uint16 next,
            uint16 up,
            uint16 down
        )
    {
        uint256 i = getIndex(self, acct);
        Member memory m = self.members[i - 1];

        acct = m.acct;
        isGroup = m.isGroup;
        amt = m.amt;
        prev = m.prev;
        next = m.next;
        up = m.up;
        down = m.down;
    }

    function getHPos(
        GeneralMeeting storage self,
        uint8 basedOnPar,
        uint64 amount,
        uint16 prev,
        uint16 next,
        bool rightMove
    ) internal view returns (uint16, uint16) {
        if (rightMove)
            while (self.members[next - 1].data[basedOnPar].sum > amount) {
                prev = next;
                next = self.members[next - 1].pos[basedOnPar].next;
                if (next == 0) break;
            }
        else
            while (self.members[prev - 1].data[basedOnPar].sum < amount) {
                next = prev;
                prev = self.members[prev - 1].pos[basedOnPar].prev;
                if (prev == 0) break;
            }

        return (prev, next);
    }

    function getVPos(
        GeneralMeeting storage self,
        uint8 basedOnPar,
        uint64 amount,
        uint16 up,
        uint16 down,
        bool toDown
    ) internal view returns (uint16, uint16) {
        if (toDown)
            while (self.members[down - 1].data[basedOnPar].amt > amount) {
                up = down;
                down = self.members[down - 1].pos[basedOnPar].down;
                if (down == 0) break;
            }
        else
            while (self.members[up - 1].data[basedOnPar].amt < amount) {
                down = up;
                up = self.members[up - 1].pos[basedOnPar].up;
                if (up == 0) break;
            }

        return (up, down);
    }

    function groupExist(GeneralMeeting storage self, uint16 group) internal returns (bool) {
        return (group > 0 &&
            group <= self.counterOfGroups &&
            self.leaderOf[group] > 0);
    }

    function getLeaderOf(uint16 group)
        internal
        returns (Member storage leader)
    {}
}
