/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/AdminSetting.sol";

// import "../common/config/BOSSetting.sol";
import "../common/config/BOHSetting.sol";
import "../common/config/BOASetting.sol";
import "../common/config/BOMSetting.sol";
import "../common/config/BOPSetting.sol";
import "../common/config/BOOSetting.sol";
import "../common/config/BOSSetting.sol";

import "../common/lib/SafeMath.sol";
import "../common/lib/serialNumber/ShareSNParser.sol";
import "../common/lib/serialNumber/PledgeSNParser.sol";
import "../common/lib/serialNumber/DealSNParser.sol";
import "../common/lib/serialNumber/OptionSNParser.sol";
import "../common/lib/serialNumber/VotingRuleParser.sol";

import "../common/interfaces/IBookSetting.sol";
import "../common/interfaces/IAgreement.sol";
import "../common/interfaces/IAdminSetting.sol";
import "../common/interfaces/ISigPage.sol";

// import "../books/boa/AgreementCalculator.sol";

import "../common/components/EnumsRepo.sol";

contract BOOKeeper is
    EnumsRepo,
    BOASetting,
    BOHSetting,
    BOMSetting,
    BOPSetting,
    BOOSetting,
    BOSSetting
{
    using SafeMath for uint256;
    using ShareSNParser for bytes32;
    using PledgeSNParser for bytes32;
    using DealSNParser for bytes32;
    using OptionSNParser for bytes32;
    using VotingRuleParser for bytes32;

    address[15] public termsTemplate;

    TermTitle[] private _termsForCapitalIncrease = [
        TermTitle.ANTI_DILUTION,
        TermTitle.PRE_EMPTIVE
    ];

    TermTitle[] private _termsForShareTransfer = [
        TermTitle.LOCK_UP,
        TermTitle.FIRST_REFUSAL,
        TermTitle.TAG_ALONG
    ];

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ################
    // ##   Events   ##
    // ################

    event AddTemplate(uint8 title, address add);

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier beEstablished(address body) {
        require(ISigPage(body).isEstablished(), "Doc NOT Established");
        _;
    }

    modifier notEstablished(address body) {
        require(!ISigPage(body).isEstablished(), "Doc ALREADY Established");
        _;
    }

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "NOT Admin of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(msg.sender), "NOT Party of Doc");
        _;
    }

    modifier onlyRightholder(bytes32 sn) {
        (, address rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
        require(msg.sender == rightholder, "NOT rightholder");
        _;
    }

    modifier onlySeller(bytes32 sn) {
        address seller = msg.sender;

        if (sn.typeOfOpt() > 0) {
            (, address rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(seller == rightholder, "NOT seller");
        } else require(seller == sn.obligorOfOpt(), "NOT seller");

        _;
    }

    modifier onlyBuyer(bytes32 sn) {
        address buyer = msg.sender;

        if (sn.typeOfOpt() > 0)
            require(buyer == sn.obligorOfOpt(), "NOT buyer");
        else {
            (, address rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(buyer == rightholder, "NOT buyer");
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function execOption(bytes32 sn, uint32 exerciseDate)
        external
        onlyRightholder(sn)
    {
        _boo.execOption(sn.shortOfOpt(), exerciseDate);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external onlyRightholder(sn) {
        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.addFuture(sn.shortOfOpt(), shareNumber, paidPar, paidPar);
    }

    function removeFuture(bytes32 sn, bytes32 ft) external onlyRightholder(sn) {
        _boo.removeFuture(sn.shortOfOpt(), ft);
        _bos.increaseCleanPar(ft.shortShareNumberOfFt(), ft.paidParOfFt());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external onlySeller(sn) {
        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.requestPledge(sn.shortOfOpt(), shareNumber, paidPar);
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external onlySeller(sn) {
        _boo.lockOption(sn.shortOfOpt(), hashLock);
    }

    function _recoverCleanPar(bytes32[] plds) private {
        uint256 len = plds.length;

        for (uint256 i = 0; i < len; i++)
            _bos.increaseCleanPar(
                plds[i].shortShareNumberOfFt(),
                plds[i].paidParOfFt()
            );
    }

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate
    ) external onlyBuyer(sn) {
        address buyer = msg.sender;
        uint256 price = sn.priceOfOpt();

        _boo.closeOption(sn.shortOfOpt(), hashKey, closingDate);

        bytes32[] memory fts = _boo.futures(sn.shortOfOpt());

        _recoverCleanPar(fts);

        for (uint256 i = 0; i < fts.length; i++) {
            _bos.transferShare(
                fts[i].shortShareNumberOfFt(),
                fts[i].parValueOfFt(),
                fts[i].paidParOfFt(),
                buyer,
                closingDate,
                price
            );
        }

        _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function revokeOption(bytes32 sn, uint32 revokeDate)
        external
        onlyRightholder(sn)
    {
        _boo.revokeOption(sn.shortOfOpt(), revokeDate);

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function releasePledges(bytes32 sn) external onlyRightholder(sn) {
        (, , , , , , uint8 state) = _boo.getOption(sn.shortOfOpt());

        require(state == 6, "option NOT revoked");

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
    }
}
