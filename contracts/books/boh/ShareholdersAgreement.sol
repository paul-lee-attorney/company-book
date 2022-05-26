/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/access/interfaces/IAccessControl.sol";
import "../../common/access/interfaces/IDraftControl.sol";
import "../../common/ruting/interfaces/IBookSetting.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BOMSetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/AddrBook.sol";

import "../../common/components/SigPage.sol";
import "../../common/components/EnumsRepo.sol";
import "../../common/utils/CloneFactory.sol";

import "./interfaces/ITerm.sol";

import "./terms/VotingRules.sol";

contract ShareholdersAgreement is
    EnumsRepo,
    CloneFactory,
    VotingRules,
    BOMSetting,
    BOSSetting,
    SigPage
{
    using ArrayUtils for address[];
    using ArrayUtils for uint8[];
    using AddrBook for AddrBook.Book;

    // title => template address
    mapping(uint8 => address) public tempOfTitle;

    // title => body
    mapping(uint8 => address) private _titleToBody;

    // body => title
    mapping(address => uint8) private _bodyToTitle;

    // bodys
    AddrBook.Book private _terms;

    // // body => bool
    // mapping(address => bool) public registered;

    // address[] private _terms;

    //##############
    //##  Event   ##
    //##############

    event AddTermToFolder(uint8 indexed typeOfDeal, uint8 title);

    event RemoveTermFromFolder(uint8 indexed typeOfDeal, uint8 title);

    event SetTemplate(uint8 indexed title, address tempAdd);

    event RemoveTemplate(uint8 indexed title);

    event CreateTerm(uint8 indexed title, address indexed body, uint32 creator);

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

    function setTermsTemplate(address[15] templates) external onlyKeeper {
        for (uint8 i = 0; i < 15; i++) {
            _setTemplate(i, templates[i]);
        }
    }

    function _setTemplate(uint8 title, address tempAdd) private {
        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.LOCK_UP) ||
            title == uint8(TermTitle.TAG_ALONG) ||
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.OPTIONS) ||
            title == uint8(TermTitle.FIRST_REFUSAL) ||
            title == uint8(TermTitle.GROUPS_UPDATE)
        ) {
            tempOfTitle[title] = tempAdd;

            emit SetTemplate(title, tempAdd);
        }
    }

    function removeTemplate(uint8 title)
        external
        onlyOwner
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

        IAccessControl(body).init(getOwner(), _rc.userNo(this), address(_rc));

        IDraftControl(body).setGeneralCounsel(_rc.userNo(this));

        _copyRoleTo(body, ATTORNEYS);

        IBookSetting(body).setBOS(address(_bos));
        if (title != uint8(TermTitle.VOTING_RULES))
            IBookSetting(body).setBOM(address(_bom));

        _titleToBody[title] = body;
        _bodyToTitle[body] = title;

        _terms.addChapter(body);
        // // registered[body] = true;
        // _terms.push(body);

        emit CreateTerm(title, body, _msgSender());
    }

    function removeTerm(uint8 title) external onlyAttorney {
        delete _bodyToTitle[_titleToBody[title]];

        delete _titleToBody[title];

        // delete registered[_titleToBody[title]];
        // _terms.removeByValue(_titleToBody[title]);

        _terms.removeChapter(_titleToBody[title]);

        emit RemoveTerm(title);
    }

    function finalizeSHA() external onlyGC {
        address[] memory clauses = _terms.getChapters();
        uint256 len = clauses.length;

        for (uint256 i = 0; i < len; i++) {
            IDraftControl(clauses[i]).lockContents();
        }

        circulateDoc();
    }

    function kill() external onlyDirectKeeper {
        selfdestruct(getDirectKeeper());
    }

    //##################
    //##    读接口    ##
    //##################

    function isTerm(address addr) external view returns (bool) {
        return _terms.isChapter(addr);
    }

    function terms() external view returns (address[]) {
        return _terms.getChapters();
    }

    function getTerm(uint8 title)
        external
        view
        titleExist(title)
        returns (address body)
    {
        body = _titleToBody[title];
    }

    function hasTitle(uint8 title) external view returns (bool) {
        return _titleToBody[title] != address(0);
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