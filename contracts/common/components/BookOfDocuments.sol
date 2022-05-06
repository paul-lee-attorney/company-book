/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../lib/serialNumber/SNFactory.sol";
import "../lib/serialNumber/DocSNParser.sol";
import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "../config/BOSSetting.sol";

import "./CloneFactory.sol";

contract BookOfDocuments is CloneFactory, BOSSetting {
    using SNFactory for bytes;
    using SNFactory for bytes32;
    using DocSNParser for bytes32;
    // using SafeMath for uint256;
    using ArrayUtils for bytes32[];

    string public bookName;
    address public template;

    struct Doc {
        bytes32 sn;
        uint32 submitDate;
        bytes32 docHash;
        uint8 state; // 0-draft 1-submitted 2-closed/effective 3-terminated/revoked
    }

    // struct snInfo {
    //     uint8 docType;           1
    //     uint16 sequence;         2
    //     uint32 createDate;       4
    //     address creator;         20
    //     bytes5 addrSuffixOfDoc;  5
    // }

    // addrOfBody => Doc
    mapping(address => Doc) internal _docs;

    // addrOfBody => bool
    mapping(address => bool) public isRegistered;

    bytes32[] private _docsList;

    uint16 public counterOfDocs;

    constructor(
        string _bookName,
        address _admin,
        address _bookeeper
    ) public {
        bookName = _bookName;
        init(_admin, _bookeeper);
    }

    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address temp);

    event CreateDoc(bytes32 indexed sn, address body);

    event RemoveDoc(bytes32 indexed sn, address body);

    event SubmitDoc(bytes32 indexed sn, address submittor);

    // event SetPointer(bytes32 indexed pointer, address body);

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
        require(_docs[body].state == 0, "doc NOT pending");
        _;
    }

    modifier onlyForSubmitted(address body) {
        require(_docs[body].state == 1, "doc NOT submitted");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function _createSN(
        uint8 docType,
        uint16 sequence,
        uint32 createDate,
        address creator,
        address body
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(docType);
        _sn = _sn.sequenceToSN(1, sequence);
        _sn = _sn.dateToSN(3, createDate);
        _sn = _sn.addrToSN(7, creator);
        _sn = _sn.bytes32ToSN(27, bytes32(body), 15, 5);

        sn = _sn.bytesToBytes32();
    }

    function setTemplate(address body) external onlyAdmin {
        template = body;
        emit SetTemplate(body);
    }

    function createDoc(
        uint8 docType,
        uint32 createDate,
        address creator
    )
        external
        onlyKeeper
        tempReady
        currentDate(createDate)
        returns (address body)
    {
        body = createClone(template);

        counterOfDocs++;

        bytes32 sn = _createSN(
            docType,
            counterOfDocs,
            createDate,
            creator,
            body
        );

        _docs[body].sn = sn;

        isRegistered[body] = true;
        sn.insertToQue(_docsList);

        emit CreateDoc(sn, body);
    }

    function removeDoc(address body)
        external
        onlyKeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _docs[body].sn;

        _docsList.removeByValue(sn);

        delete _docs[body];

        delete isRegistered[body];

        emit RemoveDoc(sn, body);
    }

    function submitDoc(
        address body,
        uint32 submitDate,
        bytes32 docHash,
        address submitter
    )
        public
        onlyKeeper
        onlyRegistered(body)
        onlyForPending(body)
        currentDate(submitDate)
    {
        Doc storage doc = _docs[body];

        doc.submitDate = submitDate;
        doc.docHash = docHash;
        doc.state = 1;

        emit SubmitDoc(doc.sn, submitter);
    }

    //##################
    //##    读接口    ##
    //##################

    // function getTemplate() external view tempReady returns (address) {
    //     return template;
    // }

    function isSubmitted(address body) external view returns (bool) {
        return _docs[body].state == 1;
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
        returns (
            bytes32 sn,
            uint32 submitDate,
            bytes32 docHash,
            uint8 state
        )
    {
        Doc storage doc = _docs[body];

        sn = doc.sn;
        submitDate = doc.submitDate;
        docHash = doc.docHash;
        state = doc.state;
    }
}
