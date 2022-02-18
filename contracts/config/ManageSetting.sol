/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfShares.sol";
import "../interfaces/IShareholdersAgreement.sol";
import "../interfaces/IBookOfDocuments.sol";
import "../interfaces/IAdminSetting.sol";
import "../interfaces/IInvestorSetting.sol";

import "../common/BookOfDocuments.sol";
import "../common/EnumsRepo.sol";

import "../sha/ShareholdersAgreement.sol";

contract ManageSetting is AdminSetting, EnumsRepo {
    IBookOfShares private _bos;

    IShareholdersAgreement private _sha;

    IBookOfDocuments private _boa;

    IBookOfDocuments private _bom;

    constructor() public {
        _sha = IShareholdersAgreement(new ShareholdersAgreement());
        IAdminSetting(_sha).setBookkeeper(this);

        _boa = IBookOfDocuments(new BookOfDocuments("BookOfAgreements"));
        IAdminSetting(_boa).setBookkeeper(this);

        _bom = IBookOfDocuments(new BookOfDocuments("BookOfResolutions"));
        IAdminSetting(_bom).setBookkeeper(this);
    }

    // ##################
    // ##   Event      ##
    // ##################

    event SetBOS(address indexed manager, address bos);

    event SetDocTemplate(address indexed bookAdd, address tempAdd);

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyMembers() {
        require(_bos.isMember(msg.sender), "仅 股东 有权操作");
        _;
    }

    modifier onlyStakeholders() {
        address sender = msg.sender;
        require(
            _bos.isMember(sender) ||
                sender == getAdmin() ||
                sender == getBackup() ||
                sender == getBookkeeper(),
            "仅 利害关系方 可操作"
        );
        _;
    }

    // ##################
    // ##   设置端口   ##
    // ##################

    function setBOS(address bos) external onlyAdmin {
        IAdminSetting config = IAdminSetting(bos);
        require(config.getBookkeeper() == address(this), "簿记管理人 未设置");

        _bos = IBookOfShares(bos);
        emit SetBOS(this, bos);

        IDraftSetting(_sha).setBOS(bos);
        IDraftSetting(_boa).setBOS(bos);
        IDraftSetting(_bom).setBOS(bos);
    }

    function setDocTemplate(address bookAdd, address tempAdd)
        external
        onlyAdmin
    {
        require(
            bookAdd == address(_boa) || bookAdd == address(_bom),
            "文件簿记  地址错误"
        );

        IBookOfDocuments iBOD = IBookOfDocuments(bookAdd);
        iBOD.setTemplate(tempAdd);

        emit SetDocTemplate(bookAdd, tempAdd);
    }

    function removeDocTemplate(address bookAdd) external onlyAdmin {
        require(
            bookAdd == address(_boa) || bookAdd == address(_bom),
            "文件簿记  地址错误"
        );

        IBookOfDocuments iBOD = IBookOfDocuments(bookAdd);
        iBOD.removeTemplate();
    }

    function setTermTemplate(TermTitle title, address tempAdd)
        external
        onlyAdmin
    {
        _sha.setTemplate(title, tempAdd);
    }

    function removeTermTemplate(TermTitle title) external onlyAdmin {
        _sha.removeTemplate(title);
    }

    function setDaysForSigning(uint8 numOfDays) external onlyAdmin {
        _sha.setDaysForSigning(numOfDays);
    }

    function addInvestor(address acct) external onlyMembers {
        IInvestorSetting(_sha).addInvestor(acct);
    }

    function removeInvestor(address acct) external onlyAdmin {
        IInvestorSetting(_sha).removeInvestor(acct);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getBOS() public view onlyStakeholders returns (IBookOfShares) {
        return _bos;
    }

    function getSHA()
        public
        view
        onlyStakeholders
        returns (IShareholdersAgreement)
    {
        return _sha;
    }

    function getBOA() public view onlyStakeholders returns (IBookOfDocuments) {
        return _boa;
    }

    function getBOM() public view onlyStakeholders returns (IBookOfDocuments) {
        return _bom;
    }
}
