/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boa/interfaces/IAgreement.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/SHASetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOPSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/SafeMath.sol";
import "../common/lib/SNParser.sol";

import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/access/interfaces/IAccessControl.sol";
import "../common/components/interfaces/ISigPage.sol";

import "../common/components/EnumsRepo.sol";

import "../common/utils/Context.sol";

contract BOOKeeper is
    EnumsRepo,
    BOASetting,
    SHASetting,
    BOMSetting,
    BOPSetting,
    BOOSetting,
    BOSSetting,
    Context
{
    using SafeMath for uint256;
    using SNParser for bytes32;

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

    // constructor(address bookeeper) public {
    //     init(msg.sender, bookeeper);
    // }

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
            IAccessControl(body).getOwner() == _bridgedMsgSender,
            "NOT Admin of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(_bridgedMsgSender), "NOT Party of Doc");
        _;
    }

    modifier onlyRightholder(bytes32 sn) {
        (, uint32 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
        require(_bridgedMsgSender == rightholder, "NOT rightholder");
        _;
    }

    modifier onlySeller(bytes32 sn) {
        if (sn.typeOfOpt() > 0) {
            (, uint32 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(
                _bridgedMsgSender == rightholder,
                "msgSender NOT rightholder"
            );
        } else
            require(
                _boo.isObligor(sn.shortOfOpt(), _bridgedMsgSender),
                "msgSender NOT seller"
            );
        _;
    }

    modifier onlyBuyer(bytes32 sn) {
        if (sn.typeOfOpt() > 0)
            require(
                _boo.isObligor(sn.shortOfOpt(), _bridgedMsgSender),
                "_bridgedMsgSender NOT obligor"
            );
        else {
            (, uint32 rightholder, , , , , ) = _boo.getOption(sn.shortOfOpt());
            require(
                _bridgedMsgSender == rightholder,
                "_bridgedMsgSender NOT rightholder"
            );
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function createOption(
        uint8 typeOfOpt,
        uint32 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) external onlyDirectKeeper {
        _boo.createOption(
            typeOfOpt,
            rightholder,
            _bridgedMsgSender,
            triggerDate,
            exerciseDays,
            closingDays,
            rate,
            parValue,
            paidPar
        );

        _clearMsgSender();
    }

    function joinOptionAsObligor(bytes32 sn) external onlyDirectKeeper {
        _boo.addObligorIntoOpt(sn.shortOfOpt(), _bridgedMsgSender);
        _clearMsgSender();
    }

    function releaseObligorFromOption(bytes32 sn, uint32 obligor)
        external
        onlyDirectKeeper
        onlyRightholder(sn)
    {
        _clearMsgSender();

        _boo.removeObligorFromOpt(sn.shortOfOpt(), obligor);
    }

    function execOption(bytes32 sn, uint32 exerciseDate)
        external
        onlyDirectKeeper
        onlyRightholder(sn)
    {
        _clearMsgSender();

        _boo.execOption(sn.shortOfOpt(), exerciseDate);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external onlyDirectKeeper onlyRightholder(sn) {
        _clearMsgSender();

        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.addFuture(sn.shortOfOpt(), shareNumber, paidPar, paidPar);
    }

    function removeFuture(bytes32 sn, bytes32 ft)
        external
        onlyDirectKeeper
        onlyRightholder(sn)
    {
        _clearMsgSender();

        _boo.removeFuture(sn.shortOfOpt(), ft);
        _bos.increaseCleanPar(ft.shortShareNumberOfFt(), ft.paidParOfFt());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external onlyDirectKeeper onlySeller(sn) {
        _clearMsgSender();

        _bos.decreaseCleanPar(shareNumber.short(), paidPar);
        _boo.requestPledge(sn.shortOfOpt(), shareNumber, paidPar);
    }

    function lockOption(bytes32 sn, bytes32 hashLock)
        external
        onlyDirectKeeper
        onlySeller(sn)
    {
        _clearMsgSender();

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
    ) external onlyDirectKeeper onlyBuyer(sn) {
        uint256 price = sn.rateOfOpt();

        _boo.closeOption(sn.shortOfOpt(), hashKey, closingDate);

        bytes32[] memory fts = _boo.futures(sn.shortOfOpt());

        _recoverCleanPar(fts);

        for (uint256 i = 0; i < fts.length; i++) {
            _bos.transferShare(
                fts[i].shortShareNumberOfFt(),
                fts[i].parValueOfFt(),
                fts[i].paidParOfFt(),
                _bridgedMsgSender,
                closingDate,
                price
            );
        }

        _clearMsgSender();

        _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function revokeOption(bytes32 sn, uint32 revokeDate)
        external
        onlyDirectKeeper
        onlyRightholder(sn)
    {
        _clearMsgSender();

        _boo.revokeOption(sn.shortOfOpt(), revokeDate);

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
    }

    function releasePledges(bytes32 sn)
        external
        onlyDirectKeeper
        onlyRightholder(sn)
    {
        _clearMsgSender();

        (, , , , , , uint8 state) = _boo.getOption(sn.shortOfOpt());

        require(state == 6, "option NOT revoked");

        if (sn.typeOfOpt() > 0) _recoverCleanPar(_boo.pledges(sn.shortOfOpt()));
        else _recoverCleanPar(_boo.futures(sn.shortOfOpt()));
    }
}
