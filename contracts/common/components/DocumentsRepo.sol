/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/EnumsRepo.sol";
import "../lib/SNFactory.sol";
import "../lib/SNParser.sol";
// import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";
import "../lib/ObjsRepo.sol";

import "./ISigPage.sol";

import "../ruting/BOSSetting.sol";
import "../ruting/SHASetting.sol";

import "../utils/CloneFactory.sol";

contract DocumentsRepo is CloneFactory, SHASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjsRepo for ObjsRepo.TimeLine;
    using ArrayUtils for bytes32[];

    string private _bookName;
    address private _template;

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
    //     uint16 sequence;         2
    //     uint32 createDate;       4
    //     uint40 creator;          4
    //     address addrOfDoc;       20
    // }

    // addrOfBody => Doc
    mapping(address => Doc) internal _docs;

    // addrOfBody => bool
    mapping(address => bool) private _isRegistered;

    bytes32[] private _docsList;

    uint16 private _counterOfDocs;

    constructor(
        string bookName,
        uint40 _owner,
        uint40 _bookeeper,
        address _rc
    ) public {
        _bookName = bookName;
        init(_owner, _bookeeper, _rc);
    }

    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address temp);

    event UpdateStateOfDoc(bytes32 indexed sn, uint8 state, uint40 caller);

    event RemoveDoc(bytes32 indexed sn, uint40 caller);

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady() {
        require(_template != address(0), "template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(_isRegistered[body], "doc NOT registered");
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

    function setTemplate(address body) external onlyOwner {
        _template = body;
        emit SetTemplate(body);
    }

    function _createSN(
        uint8 docType,
        uint16 sequence,
        uint32 createDate,
        uint40 creator,
        address body
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(docType);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, createDate);
        _sn = _sn.acctToSN(7, creator);
        _sn = _sn.addrToSN(12, body);

        sn = _sn.bytesToBytes32();
    }

    function createDoc(uint8 docType, uint40 creator)
        external
        onlyDirectKeeper
        tempReady
        returns (address body)
    {
        body = createClone(_template);

        _counterOfDocs++;

        bytes32 sn = _createSN(
            docType,
            _counterOfDocs,
            uint32(block.timestamp),
            creator,
            body
        );

        Doc storage doc = _docs[body];

        doc.sn = sn;
        doc.states.pushToNextState();

        _isRegistered[body] = true;
        sn.insertToQue(_docsList);

        emit UpdateStateOfDoc(sn, doc.states.currentState, creator);
    }

    function removeDoc(address body, uint40 caller)
        external
        onlyDirectKeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _docs[body].sn;

        _docsList.removeByValue(sn);

        delete _docs[body];
        delete _isRegistered[body];

        emit RemoveDoc(sn, caller);
    }

    function circulateDoc(
        address body,
        bytes32 rule,
        uint40 submitter
    ) public onlyDirectKeeper onlyRegistered(body) onlyForPending(body) {
        Doc storage doc = _docs[body];

        // bytes32 rule = _getSHA().votingRules(doc.sn.typeOfDoc());

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
    //##    读接口    ##
    //##################

    function bookName() external view onlyUser returns (string) {
        return _bookName;
    }

    function template() external view onlyUser returns (address) {
        return _template;
    }

    function isRegistered(address body) external view onlyUser returns (bool) {
        return _isRegistered[body];
    }

    function counterOfDocs() external view onlyUser returns (uint16) {
        return _counterOfDocs;
    }

    function passedReview(address body)
        external
        view
        onlyRegistered(body)
        onlyUser
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
        onlyUser
        onlyRegistered(body)
        returns (bool)
    {
        return
            _docs[body].states.currentState >=
            uint8(EnumsRepo.BODStates.Circulated);
    }

    function qtyOfDocs() external view onlyUser returns (uint256) {
        return _docsList.length;
    }

    function docsList() external view onlyUser returns (bytes32[]) {
        return _docsList;
    }

    function getDoc(address body)
        external
        view
        onlyRegistered(body)
        onlyUser
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
        onlyUser
        returns (uint8)
    {
        return _docs[body].states.currentState;
    }

    function startDateOf(address body, uint8 state)
        external
        view
        onlyRegistered(body)
        onlyUser
        returns (uint32)
    {
        require(state <= _docs[body].states.currentState, "state overflow");
        return uint32(_docs[body].states.startDateOf[state]);
    }

    function reviewDeadlineBNOf(address body)
        external
        view
        onlyRegistered(body)
        onlyUser
        returns (uint32)
    {
        return _docs[body].reviewDeadlineBN;
    }

    function votingDeadlineBNOf(address body)
        external
        view
        onlyRegistered(body)
        onlyUser
        returns (uint32)
    {
        return _docs[body].votingDeadlineBN;
    }
}
