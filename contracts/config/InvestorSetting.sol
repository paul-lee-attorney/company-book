/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./DraftSetting.sol";
import "../lib/ArrayUtils.sol";

contract InvestorSetting is DraftSetting {
    using ArrayUtils for address[];

    mapping(address => bool) private _investorFlag;

    address[] private _investors;

    // ##################
    // ##   Event      ##
    // ##################

    event AddInvestor(address investor);

    event RemoveInvestor(address investor);

    // ##################
    // ##   修饰器     ##
    // ##################

    modifier onlyInvestor() {
        require(_investorFlag[msg.sender], "仅 投资人 可操作");
        _;
    }

    modifier onlyMemberOrInvestor() {
        address sender = msg.sender;
        require(
            getBOS().isMember(sender) || _investorFlag[sender],
            "仅 股东 或 投资人 可操作"
        );
        _;
    }

    modifier isMemberOrInvestor(address acct) {
        require(
            getBOS().isMember(acct) || _investorFlag[acct],
            "并非 股东 或 投资人"
        );
        _;
    }

    modifier onlyStakeholders() {
        address sender = msg.sender;
        require(
            sender == getAdmin() ||
                sender == getAttorney() ||
                sender == getBookkeeper() ||
                getBOS().isMember(sender) ||
                _investorFlag[sender],
            "仅 利害关系方 可操作"
        );
        _;
    }

    // ##################
    // ##   设置端口   ##
    // ##################

    function addInvestor(address acct) external onlyMember {
        require(!_investorFlag[acct], "不可重复添加");
        _investorFlag[acct] = true;
        _investors.push(acct);
        emit AddInvestor(acct);
    }

    function removeInvestor(address acct) external onlyAdmin {
        require(_investorFlag[acct], "投资人 不存在");
        delete _investorFlag[acct];
        _investors.removeByValue(acct);
        emit RemoveInvestor(acct);
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getInvestors() public view returns (address[]) {
        return _investors;
    }

    function isInvestor(address acct) public view returns (bool) {
        return _investorFlag[acct];
    }
}
