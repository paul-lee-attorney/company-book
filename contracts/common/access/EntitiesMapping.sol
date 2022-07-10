/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/EnumerableSet.sol";
import "../lib/RelationGraph.sol";
import "../lib/EnumsRepo.sol";

contract EntitiesMapping {
    using RelationGraph for RelationGraph.Graph;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Entity {
        // role => user
        mapping(uint8 => uint40) members;
    }

    // userNo => entityNo
    mapping(uint40 => uint40) private _entityNo;

    // entityNo => Entity
    mapping(uint40 => Entity) private _entities;

    RelationGraph.Graph private _graph;

    RelationGraph.Query private _query;

    // #############
    // ##  Envet  ##
    // #############

    event CreateEntity(
        uint40 indexed entity,
        uint8 typeOfEntity,
        uint8 roleOfUser
    );

    event JoinEntity(uint40 indexed entity, uint40 user, uint8 roleOfUser);

    event QuitEntity(uint40 indexed entity, uint40 user, uint8 roleOfUser);

    event CreateConnection(
        uint40 from,
        uint40 indexed to,
        uint16 weight,
        uint8 typeOfConnection
    );

    event UpdateConnection(
        uint40 from,
        uint40 indexed to,
        uint8 typeOfConnection,
        uint16 weight
    );

    event DeleteConnection(
        uint40 from,
        uint40 indexed to,
        uint8 typeOfConnection
    );

    // ################
    // ##  Modifier  ##
    // ################

    modifier entityExist(uint40 entity) {
        require(
            _entities[entity].members[0] >
                uint8(EnumsRepo.RoleOfRegCenter.EOA) ||
                _entities[entity].members[
                    uint8(EnumsRepo.RoleOfRegCenter.BookOfShares)
                ] >
                0,
            "entity not exist"
        );
        _;
    }

    modifier connectionExist(uint88 con) {
        require(_graph.edges[con].weight > 0, "connection not exist");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    // ======== Entity ========

    function _createEntity(
        uint40 user,
        uint8 typeOfEntity,
        uint8 roleOfUser
    ) internal {
        require(
            roleOfUser == uint8(EnumsRepo.RoleOfRegCenter.EOA) ||
                roleOfUser == uint8(EnumsRepo.RoleOfRegCenter.BookOfShares),
            "only EOA and BOS may create a new Entity"
        );

        if (_graph.createVertex(user, typeOfEntity)) {
            _entityNo[user] = user;

            // _entities[user].sn = user;
            _entities[user].members[roleOfUser] = user;

            emit CreateEntity(user, typeOfEntity, roleOfUser);
        }
    }

    function _joinEntity(
        uint40 entity,
        uint40 user,
        uint8 roleOfUser
    ) internal {
        require(
            roleOfUser != uint8(EnumsRepo.RoleOfRegCenter.BookOfShares),
            "BookOfShares shall request to create an entity"
        );
        require(
            roleOfUser != uint8(EnumsRepo.RoleOfRegCenter.EOA),
            "EOA shall request to create an entity"
        );
        require(_entityNo[user] == 0, "pls quit from other Entity first");
        require(
            _entities[entity].members[roleOfUser] == 0,
            "role already be registered"
        );

        _entityNo[user] = entity;
        _entities[entity].members[roleOfUser] = user;

        emit JoinEntity(entity, user, roleOfUser);
    }

    function _quitEntity(
        uint40 entity,
        uint40 user,
        uint8 roleOfUser
    ) internal {
        require(
            roleOfUser != uint8(EnumsRepo.RoleOfRegCenter.BookOfShares),
            "BookOfShares cannot quit from company"
        );
        require(
            roleOfUser != uint8(EnumsRepo.RoleOfRegCenter.EOA),
            "EOA cannot quit from itself"
        );
        require(_entityNo[user] == entity, "wrong enityNo");
        require(
            _entities[entity].members[roleOfUser] == user,
            "wrong roleOfUser"
        );

        delete _entityNo[user];
        delete _entities[entity].members[roleOfUser];

        emit JoinEntity(entity, user, roleOfUser);
    }

    // ======== Equity ========

    function _investIn(
        uint40 usrInvestor,
        uint40 usrBOS,
        uint16 parRatio
    ) internal {
        uint40 investor = _entityNo[usrInvestor];
        uint40 company = _entityNo[usrBOS];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfRegCenter.BookOfShares)
            ] == usrBOS,
            "user is not BOS of the company"
        );

        require(parRatio > 0 && parRatio <= 10000, "parRatio overflow");

        if (
            _graph.addEdge(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                parRatio
            )
        )
            emit CreateConnection(
                investor,
                company,
                parRatio,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment)
            );
    }

    function _updateShareRatio(
        uint40 usrInvestor,
        uint40 usrBOS,
        uint16 shareRatio
    ) internal {
        uint40 investor = _entityNo[usrInvestor];
        uint40 company = _entityNo[usrBOS];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfRegCenter.BookOfShares)
            ] == usrBOS,
            "user is not BOS of the company"
        );

        if (
            _graph.updateWeight(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                shareRatio
            )
        )
            emit UpdateConnection(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                shareRatio
            );
    }

    function _exitOut(uint40 usrInvestor, uint40 usrBOS) internal {
        uint40 investor = _entityNo[usrInvestor];
        uint40 company = _entityNo[usrBOS];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfRegCenter.BookOfShares)
            ] == usrBOS,
            "user is not BOS of the company"
        );

        if (
            _graph.removeEdge(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment)
            )
        )
            emit DeleteConnection(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment)
            );
    }

    // ======== Director ========

    function _takePosition(
        uint40 usrCandy,
        uint40 usrBOD,
        uint8 title
    ) internal {
        uint40 director = _entityNo[usrCandy];
        uint40 company = _entityNo[usrBOD];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfRegCenter.BookOfDirectors)
            ] == usrBOD,
            "user is not BOD of the company"
        );

        require(
            title > uint8(EnumsRepo.TitleOfDirectors.ZeroPoint),
            "title of Director overflow"
        );
        require(
            title <= uint8(EnumsRepo.TitleOfDirectors.Director),
            "title of Director overflow"
        );

        if (
            _graph.addEdge(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director),
                title
            )
        )
            emit CreateConnection(
                director,
                company,
                title,
                uint8(EnumsRepo.TypeOfConnection.Director)
            );
    }

    function _quitPosition(uint40 usrDirector, uint40 usrBOD) internal {
        uint40 director = _entityNo[usrDirector];
        uint40 company = _entityNo[usrBOD];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfRegCenter.BookOfDirectors)
            ] == usrBOD,
            "user is not BOD of the company"
        );

        if (
            _graph.removeEdge(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director)
            )
        )
            emit DeleteConnection(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director)
            );
    }

    function _changeTitle(
        uint40 usrDirector,
        uint40 usrBOD,
        uint8 title
    ) internal {
        uint40 director = _entityNo[usrDirector];
        uint40 company = _entityNo[usrBOD];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfRegCenter.BookOfDirectors)
            ] == usrBOD,
            "user is not BOD of the company"
        );

        require(
            title > uint8(EnumsRepo.TitleOfDirectors.ZeroPoint),
            "title of Director overflow"
        );
        require(
            title <= uint8(EnumsRepo.TitleOfDirectors.Director),
            "title of Director overflow"
        );

        if (
            _graph.updateWeight(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director),
                title
            )
        )
            emit UpdateConnection(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director),
                title
            );
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function _getEntityNo(uint40 user) internal view returns (uint40) {
        return _entityNo[user];
    }

    function getMemberOf(uint40 entity, uint8 role)
        internal
        view
        entityExist(entity)
        returns (uint40)
    {
        return _entities[entity].members[role];
    }

    // ======== RelationGraph ========

    function _getEntity(uint40 entity)
        internal
        view
        entityExist(entity)
        returns (
            uint8,
            uint88,
            uint88,
            uint40
        )
    {
        return _graph.getVertex(entity);
    }

    function _getConnection(uint88 con)
        internal
        view
        connectionExist(con)
        returns (
            uint88,
            uint88,
            uint16
        )
    {
        return _graph.getEdge(con);
    }

    function _isRoot(uint40 entity)
        internal
        view
        entityExist(entity)
        returns (bool)
    {
        return _graph.isRoot(entity);
    }

    function _isLeaf(uint40 entity)
        internal
        view
        entityExist(entity)
        returns (bool)
    {
        return _graph.isLeaf(entity);
    }

    function _getUpBranch(uint40 origin)
        internal
        entityExist(origin)
        returns (uint40[] entities, uint88[] connections)
    {
        _graph.getUpBranch(origin, _query);

        entities = _query.vertices.valuesToUint40();
        connections = _query.edges.valuesToUint88();

        _query.vertices.emptyItems();
        _query.edges.emptyItems();
    }

    function _getDownBranch(uint40 origin)
        internal
        entityExist(origin)
        returns (uint40[] entities, uint88[] connections)
    {
        _graph.getDownBranch(origin, _query);

        entities = _query.vertices.valuesToUint40();
        connections = _query.edges.valuesToUint88();

        _query.vertices.emptyItems();
        _query.edges.emptyItems();
    }

    function _getRoundGraph(uint40 origin)
        internal
        entityExist(origin)
        returns (uint40[] entities, uint88[] connections)
    {
        _graph.getRoundGraph(origin, _query);

        entities = _query.vertices.valuesToUint40();
        connections = _query.edges.valuesToUint88();

        _query.vertices.emptyItems();
        _query.edges.emptyItems();
    }
}
