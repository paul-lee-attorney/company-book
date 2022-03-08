/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IAdminSetting.sol";
import "../interfaces/IDraftSetting.sol";
import "../interfaces/IBOSSetting.sol";
import "../interfaces/IBOMSetting.sol";

import "../lib/ArrayUtils.sol";

import "../common/SigPage.sol";
import "../common/EnumsRepo.sol";
import "../common/CloneFactory.sol";
import "../config/BOHSetting.sol";

import "./interfaces/ITerm.sol";

contract ShareholdersAgreement is EnumsRepo, CloneFactory, BOHSetting, SigPage {
    using ArrayUtils for address[];
    using ArrayUtils for uint8[];

    address public bos;
    address public bom;

    // title => template address
    mapping(uint8 => address) public tempOfTitle;

    // title => body
    mapping(uint8 => address) private _titleToBody;

    // body => title
    mapping(address => uint8) private _bodyToTitle;

    // body => bool
    mapping(address => bool) public registered;

    address[] private _terms;

    //##############
    //##  Event   ##
    //##############

    event AddTermToFolder(uint8 indexed typeOfDeal, uint8 title);

    event RemoveTermFromFolder(uint8 indexed typeOfDeal, uint8 title);

    event SetTemplate(uint8 indexed title, address tempAdd);

    event RemoveTemplate(uint8 indexed title);

    event CreateTerm(
        uint8 indexed title,
        address indexed body,
        address creator
    );

    event RemoveTerm(uint8 indexed title);

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint8 title) {
        require(
            _titleToBody[title] != address(0),
            "SHA does not have such title"
        );
        _;
    }

    modifier tempReadyFor(uint8 title) {
        require(tempOfTitle[title] != address(0), "Template NOT ready");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[18] templates) external onlyBookeeper {
        for (uint8 i = 0; i < 18; i++) {
            _setTemplate(i, templates[i]);
        }
    }

    function setBOS(address _bos) external onlyBookeeper {
        bos = _bos;
    }

    function setBOM(address _bom) external onlyBookeeper {
        bom = _bom;
    }

    function _setTemplate(uint8 title, address tempAdd) private {
        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.LOCK_UP) ||
            title == uint8(TermTitle.TAG_ALONG) ||
            title == uint8(TermTitle.VOTING_RULES)
        ) {
            tempOfTitle[title] = tempAdd;

            emit SetTemplate(title, tempAdd);
        }
    }

    function removeTemplate(uint8 title)
        external
        onlyAdmin
        tempReadyFor(title)
    {
        tempOfTitle[title] = address(0);

        emit RemoveTemplate(title);
    }

    function createTerm(uint8 title)
        external
        onlyAttorney
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(tempOfTitle[title]);
        IAdminSetting(body).init(msg.sender, this);
        IBOSSetting(body).setBOS(bos);

        if (title != uint8(TermTitle.VOTING_RULES))
            IBOMSetting(body).setBOM(bom);

        _titleToBody[title] = body;
        _bodyToTitle[body] = title;

        registered[body] = true;
        _terms.push(body);

        emit CreateTerm(title, body, msg.sender);
    }

    function removeTerm(uint8 title) external onlyAttorney {
        delete _bodyToTitle[_titleToBody[title]];

        delete registered[_titleToBody[title]];

        _terms.removeByValue(_titleToBody[title]);

        delete _titleToBody[title];

        emit RemoveTerm(title);
    }

    function finalizeSHA() external onlyAttorney {
        for (uint256 i = 0; i < _terms.length; i++) {
            IDraftSetting(_terms[i]).lockContents();
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function terms() external view returns (address[]) {
        return _terms;
    }

    function getTerm(uint8 title)
        external
        view
        titleExist(title)
        returns (address body)
    {
        body = _titleToBody[title];
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_titleToBody[title]).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_titleToBody[title]).isExempted(ia, snOfDeal);
    }
}
