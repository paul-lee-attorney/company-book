/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./EnumerableSet.sol";
import "./SNParser.sol";
import "./EnumsRepo.sol";
import "./Queue.sol";

library RelationGraph {
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for uint88;
    using Queue for Queue.UintQueue;

    struct Vertex {
        uint8 typeOfVertex; // ZeroPoint; EOA ; Company; Group
        uint40 groupNo;
        uint88 firstIn;
        uint16 numOfIn;
        uint88 firstOut;
        uint16 numOfOut;
    }

    struct Edge {
        uint88 nextIn;
        uint88 nextOut;
        uint64 weight;
    }

    struct Graph {
        mapping(uint256 => Vertex) vertices;
        mapping(uint256 => Edge) edges;
        mapping(uint256 => bool) tempCheck;
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
            v.typeOfVertex = typeOfVertex;
            return true;
        } else {
            return false;
        }
    }

    // ======== Edge ========

    function addEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge,
        uint64 weight,
        bool checkRingStruct
    ) internal returns (bool) {
        Vertex storage f = g.vertices[from];
        Vertex storage t = g.vertices[to];

        //DAG 环检测
        if (checkRingStruct) {
            g.tempCheck[from] = true;
            if (_hasRing(g, to)) {
                delete g.tempCheck[from];
                return false;
            } else delete g.tempCheck[from];
        }

        uint88 edge = _createEdge(g, from, to, typeOfEdge, weight);

        if (edge > 0) {
            Edge storage e = g.edges[edge];

            e.nextIn = t.firstIn;
            t.firstIn = edge;
            t.numOfIn++;

            e.nextOut = f.firstOut;
            f.firstOut = edge;
            f.numOfOut++;

            return true;
        } else return false;
    }

    function _hasRing(Graph storage g, uint40 to) private returns (bool) {
        g.tempCheck[to] = true;

        uint88 cur = g.vertices[to].firstOut;
        while (cur > 0) {
            uint40 son = cur.to();

            if (g.tempCheck[son]) {
                delete g.tempCheck[to];
                return true;
            }

            if (_hasRing(g, son)) {
                delete g.tempCheck[to];
                return true;
            }

            cur = g.edges[cur].nextOut;
        }

        delete g.tempCheck[to];
        return false;
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
        uint64 weight
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
        uint64 weight
    ) internal returns (bool) {
        uint88 sn = _createSN(from, to, typeOfEdge);

        Edge storage e = g.edges[sn];

        if (e.weight > 0) {
            e.weight = weight;
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
        Vertex storage f = g.vertices[from];
        Vertex storage t = g.vertices[to];

        (uint88 target, uint88 pre) = getInEdge(g, from, to, typeOfEdge);

        if (target > 0) {
            Edge storage e = g.edges[target];

            if (pre == 0) t.firstIn = e.nextIn;
            else g.edges[pre].nextIn = e.nextIn;
            t.numOfIn--;

            (, pre) = getOutEdge(g, from, to, typeOfEdge);

            if (pre == 0) f.firstOut = e.nextOut;
            else g.edges[pre].nextOut == e.nextOut;
            f.numOfOut--;

            delete g.edges[target];

            return true;
        } else {
            return false;
        }
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    // ======== Edge ========

    function isEdge(
        Graph storage g,
        uint40 from,
        uint40 to,
        uint8 typeOfEdge
    ) internal view returns (bool) {
        return g.edges[_createSN(from, to, typeOfEdge)].weight > 0;
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

    function getEdge(Graph storage g, uint88 sn)
        internal
        view
        returns (
            uint88 nextIn,
            uint88 nextOut,
            uint64 weight
        )
    {
        Edge storage e = g.edges[sn];

        nextIn = e.nextIn;
        nextOut = e.nextOut;
        weight = e.weight;
    }

    // ======== Vertex ========

    function isVertex(Graph storage g, uint40 vertex)
        internal
        view
        returns (bool)
    {
        return g.vertices[vertex].typeOfVertex > 0;
    }

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

    function getVertex(Graph storage g, uint40 vertex)
        internal
        view
        returns (
            uint8 typeOfVertex,
            uint40 groupNo,
            uint88 firstIn,
            uint16 numOfIn,
            uint88 firstOut,
            uint16 numOfOut
        )
    {
        Vertex storage v = g.vertices[vertex];

        typeOfVertex = v.typeOfVertex;
        groupNo = v.groupNo;
        firstIn = v.firstIn;
        numOfIn = v.numOfIn;
        firstOut = v.firstOut;
        numOfOut = v.numOfOut;
    }

    // ==== getGraph ====

    function getUpBranches(
        Graph storage g,
        uint40 origin,
        Query storage q
    ) internal {
        if (q.vertices.add(origin)) {
            Vertex storage v = g.vertices[origin];

            uint88 cur = v.firstIn;

            while (cur > 0) {
                getUpBranches(g, cur.from(), q);
                // q.vertices.add(g.edges[cur].from);
                q.edges.add(cur);
                cur = g.edges[cur].nextIn;
            }
        }
    }

    function getDownBranches(
        Graph storage g,
        uint40 origin,
        Query storage q
    ) internal {
        if (q.vertices.add(origin)) {
            Vertex storage v = g.vertices[origin];

            uint88 cur = v.firstOut;

            while (cur > 0) {
                getDownBranches(g, cur.to(), q);
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
