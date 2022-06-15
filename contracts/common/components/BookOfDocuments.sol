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
import "../lib/ObjGroup.sol";

import "./interfaces/ISigPage.sol";

import "../ruting/BOSSetting.sol";
import "../ruting/SHASetting.sol";

import "../utils/CloneFactory.sol";

contract BookOfDocuments is CloneFactory, SHASetting, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.TimeLine;
    using ArrayUtils for bytes32[];

    string public bookName;
    address public template;

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
        uint32 reviewDeadline;
        uint32 votingDeadline;
        ObjGroup.TimeLine states;
    }

    // struct snInfo {
    //     uint8 docType;           1
    //     uint16 sequence;         2
    //     uint32 createDate;       4
    //     uint32 creator;          4
    //     address addrOfDoc;       20
    // }

    // addrOfBody => Doc
    mapping(address => Doc) internal _docs;

    // addrOfBody => bool
    mapping(address => bool) public isRegistered;

    bytes32[] private _docsList;

    uint16 public counterOfDocs;

    constructor(
        string _bookName,
        uint32 _owner,
        uint32 _bookeeper,
        address _rc
    ) public {
        bookName = _bookName;
        init(_owner, _bookeeper, _rc);
    }

    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address temp);

    event UpdateStateOfDoc(bytes32 indexed sn, uint8 state, uint32 caller);

    event RemoveDoc(bytes32 indexed sn, uint32 caller);

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady() {
        require(template != address(0), "template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(isRegistered[body], "doc NOT registered");
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
        template = body;
        emit SetTemplate(body);
    }

    function _createSN(
        uint8 docType,
        uint16 sequence,
        uint32 createDate,
        uint32 creator,
        address body
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(docType);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, createDate);
        _sn = _sn.dateToSN(7, creator);
        _sn = _sn.addrToSN(11, body);

        sn = _sn.bytesToBytes32();
    }

    function createDoc(
        uint8 docType,
        uint32 creator,
        uint32 createDate
    ) external onlyDirectKeeper tempReady returns (address body) {
        body = createClone(template);

        counterOfDocs++;

        bytes32 sn = _createSN(
            docType,
            counterOfDocs,
            createDate,
            creator,
            body
        );

        Doc storage doc = _docs[body];

        doc.sn = sn;
        doc.states.pushToNextState(createDate);

        isRegistered[body] = true;
        sn.insertToQue(_docsList);

        emit UpdateStateOfDoc(sn, doc.states.currentState, creator);
    }

    function removeDoc(address body, uint32 caller)
        external
        onlyDirectKeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _docs[body].sn;

        _docsList.removeByValue(sn);

        delete _docs[body];
        delete isRegistered[body];

        emit RemoveDoc(sn, caller);
    }

    function circulateDoc(
        address body,
        uint32 submitter,
        uint32 circulateDate
    ) public onlyDirectKeeper onlyRegistered(body) onlyForPending(body) {
        Doc storage doc = _docs[body];

        bytes32 rule = _getSHA().votingRules(doc.sn.typeOfDoc());

        doc.reviewDeadline =
            circulateDate +
            uint32(rule.reviewDaysOfVR()) *
            86400;

        doc.votingDeadline =
            doc.reviewDeadline +
            uint32(rule.votingDaysOfVR()) *
            86400;

        doc.states.pushToNextState(circulateDate);

        emit UpdateStateOfDoc(doc.sn, doc.states.currentState, submitter);
    }

    function pushToNextState(
        address body,
        uint32 sigDate,
        uint32 caller
    ) public onlyKeeper onlyRegistered(body) {
        Doc storage doc = _docs[body];

        // require(
        //     doc.states.currentState >= uint8(EnumsRepo.BODStates.Proposed),
        //     "not after Proposed"
        // );

        doc.states.pushToNextState(sigDate);

        emit UpdateStateOfDoc(doc.sn, doc.states.currentState, caller);
    }

    //##################
    //##    读接口    ##
    //##################

    function passedReview(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        Doc storage doc = _docs[body];

        if (doc.states.currentState < uint8(EnumsRepo.BODStates.Executed))
            return false;
        else if (doc.states.currentState > uint8(EnumsRepo.BODStates.Executed))
            return true;
        else if (doc.reviewDeadline > now + 15 minutes) return false;
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

    function qtyOfDocs() external view returns (uint256) {
        return _docsList.length;
    }

    function docsList() external view returns (bytes32[]) {
        return _docsList;
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
        return _docs[body].states.startDateOf[state];
    }

    function reviewDeadlineOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint32)
    {
        return _docs[body].reviewDeadline;
    }

    function votingDeadlineOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint32)
    {
        return _docs[body].votingDeadline;
    }
}
