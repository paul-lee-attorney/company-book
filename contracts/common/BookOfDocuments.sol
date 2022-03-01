/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../lib/SerialNumFactory.sol";
import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "../config/BOSSetting.sol";

import "./CloneFactory.sol";

contract BookOfDocuments is CloneFactory, BOSSetting {
    using SerialNumFactory for address;
    using SafeMath for uint256;
    using ArrayUtils for bytes32[];

    string public bookName;
    address private _template;

    struct Doc {
        address body;
        bytes32 docHash;
        uint8 state; // 0-draft 1-submitted 2-closed/effective 3-terminated/revoked
    }

    // sn => Doc
    mapping(bytes32 => Doc) internal _snToDoc;

    // body => sn
    mapping(address => bytes32) internal _bodyToSN;

    // body => bool
    mapping(address => bool) private _registered;

    bytes32[] private _docs;

    // bytes32 private _pointer;

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

    event SubmitDoc(bytes32 indexed sn, address body);

    // event SetPointer(bytes32 indexed pointer, address body);

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady() {
        require(_template != address(0), "template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(_registered[body], "doc NOT registered");
        _;
    }

    modifier onlyForPending(address body) {
        require(_snToDoc[_bodyToSN[body]].state == 0, "doc NOT pending");
        _;
    }

    modifier onlyForSubmitted(address body) {
        require(_snToDoc[_bodyToSN[body]].state == 1, "doc NOT submitted");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) external onlyAdmin {
        _template = body;
        emit SetTemplate(body);
    }

    function createDoc(uint8 docType)
        external
        onlyBookeeper
        tempReady
        returns (address body)
    {
        body = createClone(_template);

        bytes32 sn = body.createSN(docType);

        _snToDoc[sn].body = body;

        _bodyToSN[body] = sn;

        _registered[body] = true;

        _docs.push(sn);

        emit CreateDoc(sn, body);
    }

    function removeDoc(address body)
        external
        onlyBookeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _bodyToSN[body];

        delete _snToDoc[_bodyToSN[body]];

        delete _bodyToSN[body];

        delete _registered[body];

        _docs.removeByValue(sn);

        emit RemoveDoc(sn, body);
    }

    function submitDoc(address body, bytes32 docHash)
        public
        onlyBookeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _bodyToSN[body];

        Doc storage doc = _snToDoc[sn];
        doc.docHash = docHash;
        doc.state = 1;

        emit SubmitDoc(sn, body);
    }

    //##################
    //##    读接口    ##
    //##################

    function getTemplate() external view tempReady returns (address) {
        return _template;
    }

    function isRegistered(address body) external view returns (bool) {
        return _registered[body];
    }

    function isSubmitted(address body) external view returns (bool) {
        return _snToDoc[_bodyToSN[body]].state == 1;
    }

    function qtyOfDocuments() external view returns (uint256) {
        return _docs.length;
    }

    function docs() external view returns (bytes32[]) {
        return _docs;
    }

    function getDoc(bytes32 sn)
        external
        view
        onlyRegistered(_snToDoc[sn].body)
        returns (
            address body,
            bytes32 docHash,
            uint8 state
        )
    {
        body = _snToDoc[sn].body;
        docHash = _snToDoc[sn].docHash;
        state = _snToDoc[sn].state;
    }

    function getSN(address body)
        external
        view
        onlyRegistered(body)
        returns (bytes32)
    {
        return _bodyToSN[body];
    }
}
