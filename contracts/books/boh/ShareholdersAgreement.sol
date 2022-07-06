/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../common/access/IAccessControl.sol";
import "../../common/access//IDraftControl.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BOMSetting.sol";

import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/components/SigPage.sol";

import "../../common/utils/CloneFactory.sol";

import "./terms/ITerm.sol";

import "./terms/VotingRules.sol";

import "./IShareholdersAgreement.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    VotingRules,
    BOMSetting,
    BOSSetting,
    SigPage
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // title => template address
    mapping(uint8 => address) private _tempOfTitle;

    // title => body
    mapping(uint8 => address) private _titleToBody;

    // titles
    EnumerableSet.UintSet private _titles;

    // bodys
    EnumerableSet.AddressSet private _bodies;


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
        require(_tempOfTitle[title] != address(0), "Template NOT ready");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTermsTemplate(address[15] templates) external onlyDirectKeeper {
        for (uint8 i = 0; i < 15; i++) {
            _setTemplate(i, templates[i]);
        }
    }

    function _setTemplate(uint8 title, address tempAdd) private {
        if (
            title == uint8(EnumsRepo.TermTitle.LOCK_UP) ||
            title == uint8(EnumsRepo.TermTitle.ANTI_DILUTION) ||
            title == uint8(EnumsRepo.TermTitle.FIRST_REFUSAL) ||
            title == uint8(EnumsRepo.TermTitle.GROUPS_UPDATE) ||
            title == uint8(EnumsRepo.TermTitle.TAG_ALONG) ||
            title == uint8(EnumsRepo.TermTitle.DRAG_ALONG) ||
            title == uint8(EnumsRepo.TermTitle.OPTIONS)
        ) {
            _tempOfTitle[title] = tempAdd;

            emit SetTemplate(title, tempAdd);
        }
    }

    function createTerm(uint8 title)
        external
        onlyAttorney
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_tempOfTitle[title]);

        IAccessControl(body).init(getOwner(), _rc.userNo(this), address(_rc));

        IDraftControl(body).setGeneralCounsel(_rc.userNo(this));

        _copyRoleTo(body, ATTORNEYS);
        _copyRoleTo(body, KEEPERS);

        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setBOM(address(_bom));

        _titleToBody[title] = body;

        _titles.add(uint256(title));

        _bodies.add(body);

        emit CreateTerm(title, body, _msgSender());
    }

    function removeTerm(uint8 title) external onlyAttorney {
        _titles.remove(uint256(title));

        _bodies.remove(_titleToBody[title]);

        delete _titleToBody[title];

        emit RemoveTerm(title);
    }

    function finalizeSHA() external onlyGC {
        address[] memory clauses = _bodies.values();
        uint256 len = clauses.length;

        for (uint256 i = 0; i < len; i++) {
            IDraftControl(clauses[i]).lockContents();
        }

        finalizeDoc();
    }

    //##################
    //##    读接口    ##
    //##################

    function tempOfTitle(uint8 title) external view onlyUser returns (address) {
        return _tempOfTitle[title];
    }

    function hasTitle(uint8 title) external view onlyUser returns (bool) {
        return _titleToBody[title] != address(0);
    }

    function isTitle(uint8 title) external view onlyUser returns (bool) {
        return _titles.contains(uint256(title));
    }

    function isBody(address addr) external view onlyUser returns (bool) {
        return _bodies.contains(addr);
    }

    function titles() external view onlyUser returns (uint8[]) {
        return _titles.valuesToUint8();
    }

    function bodies() external view onlyUser returns (address[]) {
        return _bodies.values();
    }

    function getTerm(uint8 title)
        external
        view
        titleExist(title)
        onlyUser
        returns (address body)
    {
        body = _titleToBody[title];
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) public view titleExist(title) onlyUser returns (bool) {
        return ITerm(_titleToBody[title]).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint8 title,
        address ia,
        uint8 snOfDeal
    ) external view titleExist(title) onlyUser returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_titleToBody[title]).isExempted(ia, snOfDeal);
    }
}
