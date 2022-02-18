/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;
// pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "../lib/ArrayUtils.sol";

import "../interfaces/IAdminSetting.sol";
import "../interfaces/IDraftSetting.sol";
import "../interfaces/IBookOfAgreements.sol";

import "../config/BOSSetting.sol";

import "../common/CloneFactory.sol";

contract BookOfAgreements is IBookOfAgreements, CloneFactory, BOSSetting {
    using SafeMath for uint256;
    using ArrayUtils for address[];

    address private _template;

    struct Doc {
        address body;
        bytes32 docHash;
        uint8 state;
    }

    // body => Doc
    mapping(address => Doc) private _bodyToDoc;

    // body => bool
    mapping(address => bool) private _registered;

    address[] private _docs;

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady() {
        require(_template != address(0), "请先设定 模板合约");
        _;
    }

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "仅文件 管理员 可操作"
        );
        _;
    }

    modifier onlyRegistered(address body) {
        require(_registered[body], "文件 没有注册");
        _;
    }

    modifier onlyPendingAgreement(address body) {
        require(_bodyToDoc[body].state == 0, "文件已入册");
        _;
    }

    modifier onlyLocked(address body) {
        require(IDraftSetting(body).isLocked(), "文件 尚未定稿");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body) public onlyAdmin {
        _template = body;
        emit SetTemplate(body, msg.sender);
    }

    function removeTemplate() public tempReady onlyAdmin {
        _template = address(0);
        emit SetTemplate(address(0), msg.sender);
    }

    function createAgreement()
        public
        onlyBookkeeper
        tempReady
        returns (address body)
    {
        body = createClone(_template);

        _bodyToDoc[body].body = body;
        _registered[body] = true;
        _docs.push(body);

        emit CreateAgreement(body, tx.origin);
    }

    function removeAgreement(address body)
        public
        onlyAdminOf(body)
        onlyRegistered(body)
        onlyPendingAgreement(body)
    {
        delete _bodyToDoc[body];

        delete _registered[body];

        _docs.removeByValue(body);

        emit RemoveAgreement(body, msg.sender);
    }

    function submitAgreement(address body, bytes32 docHash)
        public
        onlyBookkeeper
        onlyPendingAgreement(body)
    {

        Doc storage doc = _bodyToDoc[body];
        doc.docHash = docHash;
        doc.state = 1;

        emit SubmitAgreement(body, docHash, tx.origin);
    }

    //##################
    //##    读接口    ##
    //##################

    function getTemplate()
        public
        view
        onlyStakeholders
        tempReady
        returns (address)
    {
        return _template;
    }

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
        return _bodyToDoc[body].state == 1;
    }

    function getDocHash(address body)
        public
        view
        onlyStakeholders
        onlyRegistered(body)
        returns (bytes32 docHash)
    {
        docHash = _bodyToDoc[body].docHash;
    }

    function getQtyOfDocuments()
        public
        view
        onlyStakeholders
        returns (uint256)
    {
        return _docs.length;
    }
}
