// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IDocumentsRepo.sol";

import "../lib/EnumsRepo.sol";
import "../lib/SNFactory.sol";
import "../lib/SNParser.sol";
import "../lib/ObjsRepo.sol";
import "../lib/EnumerableSet.sol";

import "../ruting/BOSSetting.sol"; 
import "../ruting/SHASetting.sol";

import "../utils/CloneFactory.sol";

contract DocumentsRepo is IDocumentsRepo, CloneFactory, SHASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.TimeLine;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    address[18] private _templates;

    /*
    enum BODStates {
        ZeroPoint,
        Created,
        Circulated,
        Established,
        Proposed,
        Voted,
        Exercised,
        Revoked
    }
*/

    struct Doc {
        bytes32 sn;
        bytes32 docHash;
        uint32 reviewDeadlineBN;
        uint32 votingDeadlineBN;
        ObjsRepo.TimeLine states;
    }

    // struct snInfo {
    //     uint8 docType;           1
    //     uint32 sequence;         4
    //     uint32 createDate;       4
    //     uint40 creator;          5
    // }

    // addrOfBody => Doc
    mapping(address => Doc) internal _docs;

    // addrOfBody => bool
    mapping(address => bool) private _isRegistered;

    EnumerableSet.Bytes32Set private _docsList;

    uint32 private _counterOfDocs;

    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address temp, uint8 typeOfDoc);

    event UpdateStateOfDoc(bytes32 indexed sn, uint8 state, uint40 caller);

    event RemoveDoc(bytes32 indexed sn);

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady(uint8 typeOfDoc) {
        require(_templates[typeOfDoc] != address(0), "template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(
            _isRegistered[body],
            "DR.md.onlyRegistered: doc NOT registered"
        );
        _;
    }

    modifier onlyForPending(address body) {
        require(
            _docs[body].states.currentState ==
                uint8(EnumsRepo.BODStates.Created),
            "state of doc is not Created"
        );
        _;
    }

    modifier onlyForCirculated(address body) {
        require(
            _docs[body].states.currentState ==
                uint8(EnumsRepo.BODStates.Circulated),
            "state of doc is not Circulated"
        );
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body, uint8 typeOfDoc)
        external
        onlyManager(0)
    {
        require(typeOfDoc < 18, "DR.setTemplate: typeOfDoc over flow");
        _templates[typeOfDoc] = body;
        emit SetTemplate(body, typeOfDoc);
    }

    function _createSN(
        uint8 docType,
        uint32 ssn,
        uint32 createDate,
        uint40 creator
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(docType);
        _sn = _sn.dateToSN(1, ssn);
        _sn = _sn.dateToSN(5, createDate);
        _sn = _sn.acctToSN(9, creator);

        sn = _sn.bytesToBytes32();
    }

    function createDoc(uint8 docType, uint40 creator)
        public
        onlyManager(1)
        tempReady(docType)
        returns (address body)
    {
        body = createClone(_templates[docType]);

        _counterOfDocs++;

        bytes32 sn = _createSN(
            docType,
            _counterOfDocs,
            uint32(block.timestamp),
            creator
        );

        Doc storage doc = _docs[body];

        doc.sn = sn;
        doc.states.pushToNextState();

        _isRegistered[body] = true;
        _docsList.add(sn);

        emit UpdateStateOfDoc(sn, doc.states.currentState, creator);
    }

    function removeDoc(address body)
        external
        onlyManager(1)
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _docs[body].sn;

        _docsList.remove(sn);

        delete _docs[body];
        delete _isRegistered[body];

        emit RemoveDoc(sn);
    }

    function circulateDoc(
        address body,
        bytes32 rule,
        uint40 submitter
    ) public onlyManager(1) onlyRegistered(body) onlyForPending(body) {
        Doc storage doc = _docs[body];

        doc.reviewDeadlineBN =
            uint32(block.number) +
            uint32(rule.reviewDaysOfVR()) *
            24 *
            _rc.blocksPerHour();

        doc.votingDeadlineBN =
            doc.reviewDeadlineBN +
            uint32(rule.votingDaysOfVR()) *
            24 *
            _rc.blocksPerHour();

        doc.states.pushToNextState();

        emit UpdateStateOfDoc(doc.sn, doc.states.currentState, submitter);
    }

    function pushToNextState(address body, uint40 caller)
        public
        onlyKeeper
        onlyRegistered(body)
    {
        Doc storage doc = _docs[body];

        doc.states.pushToNextState();

        emit UpdateStateOfDoc(doc.sn, doc.states.currentState, caller);
    }

    //##################
    //##   read I/O   ##
    //##################

    function template(uint8 typeOfDoc) external view returns (address) {
        return _templates[typeOfDoc];
    }

    function isRegistered(address body) external view returns (bool) {
        return _isRegistered[body];
    }

    function counterOfDocs() external view returns (uint32) {
        return _counterOfDocs;
    }

    function passedReview(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        Doc storage doc = _docs[body];

        if (doc.states.currentState < uint8(EnumsRepo.BODStates.Established))
            return false;
        else if (
            doc.states.currentState > uint8(EnumsRepo.BODStates.Established)
        ) return true;
        else if (doc.reviewDeadlineBN > block.number) return false;
        else return true;
    }

    function isCirculated(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        return
            _docs[body].states.currentState >=
            uint8(EnumsRepo.BODStates.Circulated);
    }

    function qtyOfDocs() external view returns (uint256) {
        return _docsList.length();
    }

    function docsList() external view returns (bytes32[] memory) {
        return _docsList.values();
    }

    function getDoc(address body)
        external
        view
        onlyRegistered(body)
        returns (bytes32 sn, bytes32 docHash)
    {
        Doc storage doc = _docs[body];

        sn = doc.sn;
        docHash = doc.docHash;
    }

    function currentState(address body)
        external
        view
        onlyRegistered(body)
        returns (uint8)
    {
        return _docs[body].states.currentState;
    }

    function startDateOf(address body, uint8 state)
        external
        view
        onlyRegistered(body)
        returns (uint32)
    {
        require(state <= _docs[body].states.currentState, "state overflow");
        return uint32(_docs[body].states.startDateOf[state]);
    }

    function reviewDeadlineBNOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint32)
    {
        return _docs[body].reviewDeadlineBN;
    }

    function votingDeadlineBNOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint32)
    {
        return _docs[body].votingDeadlineBN;
    }
}
