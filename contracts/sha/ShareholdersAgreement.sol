/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IAdminSetting.sol";
import "../interfaces/IDraftSetting.sol";
import "../interfaces/IBOSSetting.sol";
import "../interfaces/IBOMSetting.sol";

// import "../interfaces/IShareholdersAgreement.sol";

import "../lib/ArrayUtils.sol";

import "../common/SigPage.sol";
import "../common/EnumsRepo.sol";
import "../common/CloneFactory.sol";

import "./interfaces/ITerm.sol";

// IShareholdersAgreement,
contract ShareholdersAgreement is EnumsRepo, SigPage, CloneFactory {
    using ArrayUtils for address[];
    using ArrayUtils for uint8[];

    // //Terms applicable for: 1-CapitalIncrease 2-ShareTransfer
    // uint8[][] private _checkList;

    address private _bos;
    address private _bom;

    // title => template address
    mapping(uint8 => address) private _tempOfTitle;

    // title => bool
    mapping(uint8 => bool) private _tempReadyFor;

    // title => body
    mapping(uint8 => address) private _titleToBody;

    // body => title
    mapping(address => uint8) private _bodyToTitle;

    // body => bool
    mapping(address => bool) private _registered;
    address[] private _terms;

    // uint256 private _signingDays;

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

    modifier termExist(uint8 title) {
        require(_titleToBody[title] > address(0), "Term not exist");
        _;
    }

    modifier tempReadyFor(uint8 title) {
        require(_tempReadyFor[title], "Template not ready");
        _;
    }

    modifier titleExist(uint8 title) {
        require(
            _titleToBody[title] != address(0),
            "SHA does not have such title"
        );
        _;
    }

    // modifier onlyRegistered(address body) {
    //     require(_registered[body], "条款 没有注册");
    //     _;
    // }

    // modifier typeAllowed(uint8 typeOfDeal) {
    //     require(typeOfDeal > 0 && typeOfDeal < 3, "类别编号超限");
    //     _;
    // }

    // modifier onlyAdminOf(address body) {
    //     require(
    //         IAdminSetting(body).getAdmin() == msg.sender,
    //         "仅文件 管理员 有权删除"
    //     );
    //     _;
    // }

    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[18] templates) external onlyBookeeper {
        for (uint8 i = 0; i < 18; i++) {
            _setTemplate(i, templates[i]);
        }
    }

    // function addTermToFolder(uint8 typeOfDeal, uint8 title)
    //     external
    //     onlyAdmin
    //     typeAllowed(typeOfDeal)
    // {
    //     _checkList[typeOfDeal].addValue(title);
    //     emit AddTermToFolder(typeOfDeal, title);
    // }

    // function removeTermFromFolder(uint8 typeOfDeal, uint8 title)
    //     external
    //     onlyAdmin
    //     typeAllowed(typeOfDeal)
    // {
    //     _checkList[typeOfDeal].removeByValue(title);
    //     emit RemoveTermFromFolder(typeOfDeal, title);
    // }

    function setBOS(address bos) external onlyBookeeper {
        _bos = bos;
    }

    function setBOM(address bom) external onlyBookeeper {
        _bom = bom;
    }

    function _setTemplate(uint8 title, address tempAdd) private {
        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.LOCK_UP) ||
            title == uint8(TermTitle.TAG_ALONG) ||
            title == uint8(TermTitle.VOTING_RULES)
        ) {
            _tempOfTitle[title] = tempAdd;
            _tempReadyFor[title] = true;

            emit SetTemplate(title, tempAdd);
        }
    }

    function removeTemplate(uint8 title)
        external
        onlyAdmin
        tempReadyFor(title)
    {
        _tempOfTitle[title] = address(0);
        _tempReadyFor[title] = false;

        emit RemoveTemplate(title);
    }

    function createTerm(uint8 title)
        external
        onlyAttorney
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_tempOfTitle[title]);
        IAdminSetting(body).init(msg.sender, this);
        IBOSSetting(body).setBOS(_bos);

        if (title != uint8(TermTitle.VOTING_RULES))
            IBOMSetting(body).setBOM(_bom);

        _titleToBody[title] = body;
        _bodyToTitle[body] = title;

        _registered[body] = true;
        _terms.push(body);

        emit CreateTerm(title, body, msg.sender);
    }

    function removeTerm(uint8 title)
        external
        onlyAttorney // onlyForDraft
    {
        delete _bodyToTitle[_titleToBody[title]];

        delete _registered[_titleToBody[title]];

        _terms.removeByValue(_titleToBody[title]);

        delete _titleToBody[title];

        emit RemoveTerm(title);
    }

    function finalizeSHA() external onlyAttorney {
        for (uint256 i = 0; i < _terms.length; i++) {
            IDraftSetting(_terms[i]).lockContents();
            // IAdminSetting(_terms[i]).abandonAdmin();
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function getTerm(uint8 title)
        external
        view
        titleExist(title)
        returns (address body)
    {
        body = _titleToBody[title];
    }

    function getTerms() external view returns (address[] terms) {
        terms = _terms;
    }

    // function getCheckList(uint8 typeOfDeal)
    //     external
    //     view
    //     returns (
    //         // typeAllowed(typeOfDeal)
    //         uint8[] titles
    //     )
    // {
    //     titles = _checkList[typeOfDeal];
    // }

    function getTemplate(uint8 title)
        external
        view
        tempReadyFor(title)
        returns (address)
    {
        return _tempOfTitle[title];
    }

    function getBOS() external view returns (address) {
        return _bos;
    }

    function getBOM() external view returns (address) {
        return _bom;
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_titleToBody[title]).isTriggered(ia, snOfDeal);
    }

    // function dealIsTriggered(
    //     address ia,
    //     uint8 snOfDeal,
    //     uint8 typeOfDeal
    // ) public view returns (bool flag, uint8[] triggers) {
    //     uint8[] terms = _checkList[typeOfDeal];
    //     uint8[] _triggers;
    //     for (uint8 i = 0; i < terms.length; i++) {
    //         if (termIsTriggered(uint8(terms[i]), ia, snOfDeal)) {
    //             flag = true;
    //             _triggers.push(terms[i]);
    //         }
    //     }
    //     triggers = _triggers;
    // }

    function termIsExempted(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) public view onlyBookeeper titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_titleToBody[title]).isExempted(ia, snOfDeal);
    }

    // function dealIsExempted(
    //     address ia,
    //     uint8 snOfDeal,
    //     uint8 typeOfDeal
    // ) public view returns (bool flag, uint8[] triggers) {
    //     uint8[] memory tempTriggers;

    //     (flag, tempTriggers) = dealIsTriggered(ia, snOfDeal, typeOfDeal);

    //     if (!flag) {
    //         flag = true;
    //         return;
    //     }

    //     uint8[] _triggers;

    //     for (uint8 i = 0; i < tempTriggers.length; i++) {
    //         if (!termIsExempted(tempTriggers[i], ia, snOfDeal)) {
    //             flag = false;
    //             _triggers.push(tempTriggers[i]);
    //         }
    //     }

    //     if (!flag) triggers = _triggers;
    // }
}
