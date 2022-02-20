/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;
// pragma experimental ABIEncoderV2;

import "../lib/SerialNumFactory.sol";
import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";
// import "../interfaces/IBOSSetting.sol";
import "../interfaces/IAdminSetting.sol";
import "../interfaces/IDraftSetting.sol";

import "../config/AdminSetting.sol";
import "./CloneFactory.sol";

contract BookOfDocuments is CloneFactory, AdminSetting {
    using SerialNumFactory for address;
    using SafeMath for uint256;
    using ArrayUtils for bytes32[];

    string private _bookName;
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
        string bookName,
        address admin,
        address bookkeeper
    ) public {
        _bookName = bookName;
        init(admin, bookkeeper);
    }

    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address indexed self, address temp);

    event SetBookSetting(address indexed self, address book);

    event ResetBookSetting();

    event CreateDoc(
        address indexed self,
        address indexed doc,
        bytes32 indexed sn
    );

    event RemoveDoc(address indexed self, bytes32 indexed sn, address body);

    event SubmitDoc(address indexed self, bytes32 indexed sn, address body);

    event SetPointer(
        address indexed self,
        bytes32 indexed pointer,
        address body
    );

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady() {
        require(_template != address(0), "请先设定 模板合约");
        _;
    }

    modifier onlyRegistered(address body) {
        require(_registered[body], "文件 没有注册");
        _;
    }

    modifier onlyForPending(address body) {
        require(_snToDoc[_bodyToSN[body]].state == 0, "文件已入册");
        _;
    }

    modifier onlyForSubmitted(address body) {
        require(_snToDoc[_bodyToSN[body]].state == 1, "文件未提交");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) public onlyAdmin {
        _template = body;
        emit SetTemplate(this, body);
    }

    // function setBookSetting(address book) public onlyAdmin {
    //     _bos = book;
    //     emit SetBookSetting(this, book);
    // }

    function createDoc(uint8 docType)
        public
        onlyBookkeeper
        tempReady
        returns (address body)
    {
        // require(_bos > 0, "请先设置文件库");

        body = createClone(_template);

        bytes32 sn = body.createSN(docType);

        _snToDoc[sn].body = body;

        _bodyToSN[body] = sn;

        _registered[body] = true;

        _docs.push(sn);

        // IAdminSetting(body).init(admin, bookkeeper)
        // IBOSSetting(body).setBOS(_bos);

        emit CreateDoc(this, body, sn);
    }

    function removeDoc(address body)
        public
        onlyBookkeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _bodyToSN[body];

        delete _snToDoc[_bodyToSN[body]];

        delete _bodyToSN[body];

        delete _registered[body];

        _docs.removeByValue(sn);

        emit RemoveDoc(this, sn, body);
    }

    function submitDoc(address body, bytes32 docHash)
        public
        onlyBookkeeper
        onlyRegistered(body)
        onlyForPending(body)
    {
        bytes32 sn = _bodyToSN[body];

        Doc storage doc = _snToDoc[sn];
        doc.docHash = docHash;
        doc.state = 1;

        emit SubmitDoc(this, sn, body);
    }

    function setPointer(address body)
        public
        onlyBookkeeper
        onlyRegistered(body)
        onlyForSubmitted(body)
    {
        _pointer = _bodyToSN[body];
        emit SetPointer(this, _pointer, body);
    }

    //##################
    //##    读接口    ##
    //##################

    function getBookName() public view onlyStakeholders returns (string) {
        return _bookName;
    }

    function getTemplate()
        public
        view
        onlyStakeholders
        tempReady
        returns (address)
    {
        return _template;
    }

    // function getBookSetting()
    //     public
    //     view
    //     onlyStakeholders
    //     tempReady
    //     returns (address)
    // {
    //     return _bos;
    // }

    function isRegistered(address body)
        public
        view
        onlyStakeholders
        returns (bool)
    {
        return _registered[body];
    }

    function isSubmitted(address body)
        public
        view
        onlyStakeholders
        onlyRegistered(body)
        returns (bool)
    {
        return _snToDoc[_bodyToSN[body]].state == 1;
    }

    function getQtyOfDocuments()
        public
        view
        onlyStakeholders
        returns (uint256)
    {
        return _docs.length;
    }

    function getDocs() public view onlyStakeholders returns (bytes32[]) {
        return _docs;
    }

    function getDoc(bytes32 sn)
        public
        view
        onlyStakeholders
        returns (
            // onlyRegistered(_snToDoc[sn].body)
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
        public
        view
        onlyStakeholders
        onlyRegistered(body)
        returns (bytes32)
    {
        return _bodyToSN[body];
    }

    function getPointer() public view onlyStakeholders returns (bytes32) {
        return _pointer;
    }

    function getTheOne() public view onlyStakeholders returns (address) {
        return _snToDoc[_pointer].body;
    }
}
