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
        mapping(uint40 => bool) isKeeper;
        // RoleOfUser => user
        mapping(uint8 => uint40) members;
    }

    // userNo => entityNo
    mapping(uint40 => uint40) internal _entityNo;

    // entityNo => Entity
    mapping(uint40 => Entity) internal _entities;

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
        uint64 weight,
        uint8 typeOfConnection,
        bool checkRingStruct
    );

    event UpdateConnection(
        uint40 from,
        uint40 indexed to,
        uint8 typeOfConnection,
        uint64 weight
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
        require(isEntity(entity), "EM.entityExist: entity not exist");
        _;
    }

    modifier connectionExist(uint88 con) {
        require(
            _graph.edges[con].weight > 0,
            "EM.connectionExist: connection not exist"
        );
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
            roleOfUser == uint8(EnumsRepo.RoleOfUser.EOA) ||
                roleOfUser == uint8(EnumsRepo.RoleOfUser.BookOfShares),
            "only EOA and BOS may create a new Entity"
        );

        if (_graph.createVertex(user, typeOfEntity)) {
            _entityNo[user] = user;

            _entities[user].members[roleOfUser] = user;

            emit CreateEntity(user, typeOfEntity, roleOfUser);
        }
    }

    function _joinEntity(
        uint40 entity,
        uint40 user,
        uint8 roleOfUser
    ) internal entityExist(entity) {
        require(_entityNo[user] == 0, "pls quit from other Entity first");

        Entity storage corp = _entities[entity];

        require(corp.members[roleOfUser] == 0, "role already be registered");

        _entityNo[user] = entity;
        corp.members[roleOfUser] = user;

        if (
            roleOfUser > uint8(EnumsRepo.RoleOfUser.GeneralKeeper) &&
            roleOfUser < uint8(EnumsRepo.RoleOfUser.BOSCalculator)
        ) {
            corp.isKeeper[user] = true;
        }

        emit JoinEntity(entity, user, roleOfUser);
    }

    function _quitEntity(uint40 user, uint8 roleOfUser) internal {
        require(
            roleOfUser > uint8(EnumsRepo.RoleOfUser.BookOfShares),
            "roleOfUser overflow"
        );
        require(
            roleOfUser < uint8(EnumsRepo.RoleOfUser.EndPoint),
            "roleOfUser overflow"
        );

        uint40 entity = _entityNo[user];

        Entity storage corp = _entities[entity];

        require(corp.members[roleOfUser] == user, "wrong roleOfUser");

        if (corp.isKeeper[user]) corp.isKeeper[user] = false;

        delete corp.members[roleOfUser];
        delete _entityNo[user];

        emit QuitEntity(entity, user, roleOfUser);
    }

    // ======== Investment ========

    function _investIn(
        uint40 usrInvestor,
        uint40 usrBOS,
        uint64 parValue,
        bool checkRingStruct
    ) internal entityExist(usrInvestor) returns (bool) {
        uint40 investor = _entityNo[usrInvestor];
        uint40 company = _entityNo[usrBOS];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfUser.BookOfShares)
            ] == usrBOS,
            "user is not BOS of the company"
        );

        require(parValue > 0, "EntitiesMapping/_investIn: zero parValue");

        if (
            _graph.addEdge(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                parValue,
                checkRingStruct
            )
        ) {
            emit CreateConnection(
                investor,
                company,
                parValue,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                checkRingStruct
            );
            return true;
        } else return false;
    }

    function _exitOut(uint40 usrInvestor, uint40 usrBOS)
        internal
        entityExist(usrInvestor)
        returns (bool)
    {
        uint40 investor = _entityNo[usrInvestor];
        uint40 company = _entityNo[usrBOS];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfUser.BookOfShares)
            ] == usrBOS,
            "user is not BOS of the company"
        );

        if (
            _graph.removeEdge(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment)
            )
        ) {
            emit DeleteConnection(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment)
            );
            return true;
        } else return false;
    }

    function _updateParValue(
        uint40 usrInvestor,
        uint40 usrBOS,
        uint64 parValue
    ) internal entityExist(usrInvestor) returns (bool) {
        uint40 investor = _entityNo[usrInvestor];
        uint40 company = _entityNo[usrBOS];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfUser.BookOfShares)
            ] == usrBOS,
            "user is not BOS of the company"
        );

        require(parValue > 0, "EntitiesMapping/_updateParValue: zero parValue");

        if (
            _graph.updateWeight(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                parValue
            )
        ) {
            emit UpdateConnection(
                investor,
                company,
                uint8(EnumsRepo.TypeOfConnection.EquityInvestment),
                parValue
            );
            return true;
        } else return false;
    }

    // ======== Director ========

    function _takePosition(
        uint40 usrCandy,
        uint40 usrBOD,
        uint8 title
    ) internal entityExist(usrCandy) returns (bool) {
        uint40 director = _entityNo[usrCandy];
        uint40 company = _entityNo[usrBOD];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfUser.BookOfDirectors)
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
                title,
                false
            )
        ) {
            emit CreateConnection(
                director,
                company,
                title,
                uint8(EnumsRepo.TypeOfConnection.Director),
                false
            );
            return true;
        } else return false;
    }

    function _quitPosition(uint40 usrDirector, uint40 usrBOD)
        internal
        entityExist(usrDirector)
        returns (bool)
    {
        uint40 director = _entityNo[usrDirector];
        uint40 company = _entityNo[usrBOD];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfUser.BookOfDirectors)
            ] == usrBOD,
            "user is not BOD of the company"
        );

        if (
            _graph.removeEdge(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director)
            )
        ) {
            emit DeleteConnection(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director)
            );
            return true;
        } else return false;
    }

    function _changeTitle(
        uint40 usrDirector,
        uint40 usrBOD,
        uint8 title
    ) internal entityExist(usrDirector) returns (bool) {
        uint40 director = _entityNo[usrDirector];
        uint40 company = _entityNo[usrBOD];

        require(
            _entities[company].members[
                uint8(EnumsRepo.RoleOfUser.BookOfDirectors)
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
        ) {
            emit UpdateConnection(
                director,
                company,
                uint8(EnumsRepo.TypeOfConnection.Director),
                title
            );
            return true;
        } else return false;
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isEntity(uint40 entity) public view returns (bool) {
        return (_entities[entity].members[uint8(EnumsRepo.RoleOfUser.EOA)] >
            0 ||
            _entities[entity].members[
                uint8(EnumsRepo.RoleOfUser.BookOfShares)
            ] >
            0);
    }

    function _isKeeper(uint40 entity, uint40 user)
        internal
        view
        returns (bool)
    {
        return _entities[entity].isKeeper[user];
    }

    function _memberOfEntity(uint40 entity, uint8 role)
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
            uint40,
            uint88,
            uint16,
            uint88,
            uint16
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
            uint64
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

    function _getUpBranches(uint40 origin)
        internal
        entityExist(origin)
        returns (uint40[] entities, uint88[] connections)
    {
        _graph.getUpBranches(origin, _query);

        entities = _query.vertices.valuesToUint40();
        connections = _query.edges.valuesToUint88();

        _query.vertices.emptyItems();
        _query.edges.emptyItems();
    }

    function _getDownBranches(uint40 origin)
        internal
        entityExist(origin)
        returns (uint40[] entities, uint88[] connections)
    {
        _graph.getDownBranches(origin, _query);

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
