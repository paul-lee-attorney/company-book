/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./EnumerableSet.sol";
import "./SNParser.sol";

library RelationGraph {
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for uint88;

    struct Vertex {
        // uint40 sn;
        uint8 typeOfVertex; // ZeroPoint; EOA ; Company; Group
        uint88 firstIn;
        uint88 firstOut;
        uint40 groupNo;
    }

    struct Edge {
        // uint8 typeOfEdge; // EquityInvestment; Director; Group
        // uint40 from;
        // uint40 to;
        uint88 nextOut;
        uint88 nextIn;
        uint16 weight;
    }

    struct Graph {
        // uint40 counterOfVertices;
        // uint88 counterOfEdges;
        uint40 counterOfGroups;
        mapping(uint256 => Vertex) vertices;
        mapping(uint256 => Edge) edges;
    }

    struct Query {
        EnumerableSet.UintSet vertices;
        EnumerableSet.UintSet edges;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function createVertex(
        Graph storage g,
        uint40 sn,
        uint8 typeOfVertex
    ) internal returns (bool) {
        if (g.vertices[sn].typeOfVertex == 0) {
            Vertex storage v = g.vertices[sn];
            // v.sn = sn;
            v.typeOfVertex = typeOfVertex;
            return true;
        } else {
            return false;
        }
    }

    // function joinVertex(
    //     Graph storage g,
    //     uint40 vertex,
    //     uint40 user,
    //     uint8 roleOfUser
    // ) internal returns (bool) {
    //     require(roleOfUser < 16, "roleOfUser overflow");

    //     if (g.vertices[vertex].members[roleOfUser] == 0) {
    //         g.vertices[vertex].members[roleOfUser] = user;
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    // function quitVertex(
    //     Graph storage g,
    //     uint40 vertex,
    //     uint40 user,
    //     uint8 roleOfUser
    // ) internal returns (bool) {
    //     require(roleOfUser < 16, "roleOfUser overflow");

    //     if (g.vertices[vertex].members[roleOfUser] == user) {
    //         g.vertices[vertex].members[roleOfUser] = 0;
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    // ======== Edge ========

    function addEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge,
        uint16 weight
    ) internal returns (bool) {
        Vertex storage t = g.vertices[to];
        Vertex storage f = g.vertices[from];

        uint88 edge = _createEdge(g, from, to, typeOfEdge, weight);

        if (edge > 0) {
            uint88 tail;

            if (t.firstIn == 0) t.firstIn = edge;
            else {
                tail = getTailOfInChain(g, t.firstIn);
                g.edges[tail].nextIn = edge;
            }

            if (f.firstOut == 0) f.firstOut = edge;
            else {
                tail = getTailOfOutChain(g, f.firstOut);
                g.edges[tail].nextOut = edge;
            }

            return true;
        } else return false;
    }

    function _createSN(
        uint40 from,
        uint40 to,
        uint8 typeOfEdge
    ) private pure returns (uint88) {
        return (uint88(typeOfEdge) << 80) + (uint88(from) << 40) + uint88(to);
    }

    function _createEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge,
        uint16 weight
    ) private returns (uint88) {
        uint88 sn = _createSN(from, to, typeOfEdge);

        Edge storage e = g.edges[sn];

        if (e.weight == 0) {
            e.weight = weight;
            return sn;
        } else return 0;
    }

    function updateWeight(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge,
        uint16 weight
    ) internal returns (bool) {
        (uint88 edge, ) = getInEdge(g, from, to, typeOfEdge);

        if (edge > 0) {
            g.edges[edge].weight = weight;
            return true;
        } else {
            return false;
        }
    }

    function removeEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge
    ) internal returns (bool) {
        Vertex storage t = g.vertices[to];
        Vertex storage f = g.vertices[from];

        (uint88 edge, uint88 pre) = getInEdge(g, from, to, typeOfEdge);

        if (edge > 0) {
            if (pre == 0) t.firstIn = g.edges[edge].nextIn;
            else g.edges[pre].nextIn = g.edges[edge].nextIn;

            (, pre) = getOutEdge(g, from, to, typeOfEdge);

            if (pre == 0) f.firstOut = g.edges[edge].nextOut;
            else g.edges[pre].nextOut == g.edges[edge].nextOut;

            delete g.edges[edge];

            return true;
        } else {
            return false;
        }
    }

    // ======== Group ========

    // function groupSorting(Graph storage g, uint88 edge) internal {
    //     Edge storage e = g.edges[edge];

    //     uint40 from = e.from;
    //     uint40 to = e.to;

    //     Vertex storage f = g.vertices[from];
    //     if (f.groupNo == 0) {
    //         g.counterOfGroups++;
    //         f.groupNo = g.counterOfGroups;
    //     }

    //     Vertex storage t = g.vertices[to];

    //     // if (t.groupNo)

    //     // uint88 cur = t.firstIn;

    //     // while (cur > 0) {
    //     //     if
    //     // }
    // }

    // ##################
    // ##   查询端口   ##
    // ##################

    // function getMember(
    //     Graph storage g,
    //     uint40 vertex,
    //     uint8 role
    // ) internal view returns (uint40 member) {
    //     require(role < 16, "roleOfUser overflow");
    //     return g.vertices[vertex].members[role];
    // }

    function getVertex(Graph storage g, uint40 vertex)
        internal
        view
        returns (
            uint8 typeOfVertex,
            uint88 firstIn,
            uint88 firstOut,
            uint40 groupNo
        )
    {
        Vertex storage v = g.vertices[vertex];
        typeOfVertex = v.typeOfVertex;
        firstIn = v.firstIn;
        firstOut = v.firstOut;
        groupNo = v.groupNo;
    }

    function getEdge(Graph storage g, uint88 sn)
        internal
        view
        returns (
            uint88 nextOut,
            uint88 nextIn,
            uint16 weight
        )
    {
        Edge storage e = g.edges[sn];

        if (sn.to() > 0) {
            nextOut = e.nextOut;
            nextIn = e.nextIn;
            weight = e.weight;
        }
    }

    // ======== Query ========

    function getTailOfInChain(Graph storage g, uint88 head)
        internal
        view
        returns (uint88 tail)
    {
        while (head > 0) {
            tail = head;
            head = g.edges[tail].nextIn;
        }
    }

    function getTailOfOutChain(Graph storage g, uint88 head)
        internal
        view
        returns (uint88 tail)
    {
        while (head > 0) {
            tail = head;
            head = g.edges[tail].nextOut;
        }
    }

    function getInEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge
    ) internal view returns (uint88 target, uint88 pre) {
        target = g.vertices[to].firstIn;
        while (target > 0) {
            if (target == _createSN(from, to, typeOfEdge)) return (target, pre);
            pre = target;
            target = g.edges[pre].nextIn;
        }
        return (target, pre);
    }

    function getOutEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge
    ) internal view returns (uint88 target, uint88 pre) {
        target = g.vertices[from].firstOut;
        while (target > 0) {
            if (target == _createSN(from, to, typeOfEdge)) return (target, pre);
            pre = target;
            target = g.edges[pre].nextOut;
        }
        return (target, pre);
    }

    // ======== Vertex ========

    function isRoot(Graph storage g, uint40 vertex)
        internal
        view
        returns (bool)
    {
        Vertex storage v = g.vertices[vertex];
        return (v.firstIn == 0 && v.firstOut > 0);
    }

    function isLeaf(Graph storage g, uint40 vertex)
        internal
        view
        returns (bool)
    {
        Vertex storage v = g.vertices[vertex];
        return (v.firstOut == 0 && v.firstIn > 0);
    }

    // ==== getGraph ====

    function getUpBranch(
        Graph storage g,
        uint40 origin,
        Query storage q
    ) internal {
        if (q.vertices.add(origin)) {
            Vertex storage v = g.vertices[origin];

            uint88 cur = v.firstIn;

            while (cur > 0) {
                getUpBranch(g, cur.from(), q);
                // q.vertices.add(g.edges[cur].from);
                q.edges.add(cur);
                cur = g.edges[cur].nextIn;
            }
        }
    }

    function getDownBranch(
        Graph storage g,
        uint40 origin,
        Query storage q
    ) internal {
        if (q.vertices.add(origin)) {
            Vertex storage v = g.vertices[origin];

            uint88 cur = v.firstOut;

            while (cur > 0) {
                getDownBranch(g, cur.to(), q);
                // q.vertices.add(g.edges[cur].to);
                q.edges.add(cur);
                cur = g.edges[cur].nextOut;
            }
        }
    }

    function getRoundGraph(
        Graph storage g,
        uint40 origin,
        Query storage q
    ) internal {
        if (q.vertices.add(origin)) {
            Vertex storage v = g.vertices[origin];

            uint88 cur = v.firstIn;

            while (cur > 0) {
                getRoundGraph(g, cur.from(), q);
                q.edges.add(cur);

                cur = g.edges[cur].nextIn;
            }

            cur = v.firstOut;

            while (cur > 0) {
                getRoundGraph(g, cur.to(), q);
                q.edges.add(cur);

                cur = g.edges[cur].nextOut;
            }
        }
    }
}
