/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../lib/SerialNumFactory.sol";
import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "../config/AdminSetting.sol";
import "./CloneFactory.sol";

contract BookOfDocuments is CloneFactory, AdminSetting {
    using SerialNumFactory for address;
    using SafeMath for uint256;
    using ArrayUtils for bytes32[];

    string public bookName;
    address private _template;

    struct Doc {
        address body;
        bytes32 docHash;
        uint8 state; // 0-draft 1-submitted
    }

    // sn => Doc
    mapping(bytes32 => Doc) private _snToDoc;

    // body => sn
    mapping(address => bytes32) private _bodyToSN;

    // body => bool
    mapping(address => bool) private _registered;

    bytes32[] private _docs;

    bytes32 private _pointer;

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

    event CreateDoc(bytes32 indexed sn, address doc);

    event RemoveDoc(bytes32 indexed sn, address body);

    event SubmitDoc(bytes32 indexed sn, address body);

    event SetPointer(bytes32 indexed pointer, address body);

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
        external
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

    function setPointer(address body)
        external
        onlyBookeeper
        onlyRegistered(body)
        onlyForSubmitted(body)
    {
        _pointer = _bodyToSN[body];
        emit SetPointer(_pointer, body);
    }

    //##################
    //##    读接口    ##
    //##################

    function getTemplate()
        external
        view
        onlyStakeholders
        tempReady
        returns (address)
    {
        return _template;
    }

    function isRegistered(address body)
        external
        view
        onlyStakeholders
        returns (bool)
    {
        return _registered[body];
    }

    function isSubmitted(address body)
        external
        view
        onlyStakeholders
        onlyRegistered(body)
        returns (bool)
    {
        return _snToDoc[_bodyToSN[body]].state == 1;
    }

    function getQtyOfDocuments()
        external
        view
        onlyStakeholders
        returns (uint256)
    {
        return _docs.length;
    }

    function getDocs() external view onlyStakeholders returns (bytes32[]) {
        return _docs;
    }

    function getDoc(bytes32 sn)
        external
        view
        onlyStakeholders
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
        onlyStakeholders
        onlyRegistered(body)
        returns (bytes32)
    {
        return _bodyToSN[body];
    }

    function getPointer() external view onlyStakeholders returns (bytes32) {
        return _pointer;
    }

    function getTheOne() external view onlyStakeholders returns (address) {
        return _snToDoc[_pointer].body;
    }
}
