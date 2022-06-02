/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/EnumsRepo.sol";
import "../lib/SNFactory.sol";
import "../lib/SNParser.sol";
import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";
import "../lib/Timeline.sol";

import "./interfaces/ISigPage.sol";

import "../ruting/BOSSetting.sol";

import "../utils/CloneFactory.sol";

contract BookOfDocuments is CloneFactory, BOSSetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using Timeline for Timeline.Line;
    using ArrayUtils for bytes32[];

    string public bookName;
    address public template;

    struct Doc {
        bytes32 sn;
        bytes32 docHash;
        uint32 reviewDeadline;
        Timeline.Line states;
    }

    // struct snInfo {
    //     uint8 docType;           1
    //     uint8 reviewDays;        1
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

    modifier onlyForSubmitted(address body) {
        require(
            _docs[body].states.currentState ==
                uint8(EnumsRepo.BODStates.Submitted),
            "state of doc is not Submitted"
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
        uint8 reviewDays,
        uint16 sequence,
        uint32 createDate,
        uint32 creator,
        address body
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(docType);
        _sn[1] = bytes1(reviewDays);
        _sn = _sn.sequenceToSN(2, sequence);
        _sn = _sn.dateToSN(4, createDate);
        _sn = _sn.dateToSN(8, creator);
        _sn = _sn.addrToSN(12, body);

        sn = _sn.bytesToBytes32();
    }

    function createDoc(
        uint8 docType,
        uint8 reviewDays,
        uint32 createDate,
        uint32 creator
    )
        external
        onlyDirectKeeper
        tempReady
        currentDate(createDate)
        returns (address body)
    {
        body = createClone(template);

        counterOfDocs++;

        bytes32 sn = _createSN(
            docType,
            reviewDays,
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

    function submitDoc(
        address body,
        uint32 submitter,
        uint32 submitDate,
        bytes32 docHash
    )
        public
        onlyDirectKeeper
        onlyRegistered(body)
        onlyForPending(body)
        currentDate(submitDate)
    {
        require(ISigPage(body).established(), "doc is not established");

        Doc storage doc = _docs[body];

        doc.docHash = docHash;
        doc.reviewDeadline = submitDate + doc.sn.reviewDaysOfDoc() * 86400;
        doc.states.pushToNextState(submitDate);

        emit UpdateStateOfDoc(doc.sn, doc.states.currentState, submitter);
    }

    function rejectDoc(
        address body,
        uint32 sigDate,
        uint32 caller
    ) public onlyDirectKeeper onlyRegistered(body) currentDate(sigDate) {
        Doc storage doc = _docs[body];

        if (doc.states.currentState == uint8(EnumsRepo.BODStates.Submitted)) {
            require(doc.reviewDeadline >= sigDate, "missed review period");

            doc.docHash = bytes32(0);
            // doc.reviewDeadline = 0;
            doc.states.backToPrevState();
            ISigPage(body).backToDraft(doc.reviewDeadline);

            emit UpdateStateOfDoc(doc.sn, doc.states.currentState, caller);
        } else
            require(
                doc.states.currentState == uint8(EnumsRepo.BODStates.Created),
                "wrong state of Doc"
            );
    }

    function pushToNextState(
        address body,
        uint32 sigDate,
        uint32 caller
    ) public onlyDirectKeeper onlyRegistered(body) currentDate(sigDate) {
        Doc storage doc = _docs[body];

        require(
            doc.states.currentState >= uint8(EnumsRepo.BODStates.Submitted),
            "not after Proposed"
        );

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

        if (doc.states.currentState < uint8(EnumsRepo.BODStates.Submitted))
            return false;
        else if (doc.states.currentState > uint8(EnumsRepo.BODStates.Submitted))
            return true;
        else if (doc.reviewDeadline > now + 15 minutes) return false;
        else return true;
    }

    function isSubmitted(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        return
            _docs[body].states.currentState >=
            uint8(EnumsRepo.BODStates.Submitted);
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
}
