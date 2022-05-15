/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/config/AdminSetting.sol";

import "../common/config/interfaces/IAdminSetting.sol";

import "./interfaces/IBOAKeeper.sol";
import "./interfaces/IBOHKeeper.sol";
import "./interfaces/IBOMKeeper.sol";
import "./interfaces/IBOOKeeper.sol";
import "./interfaces/IBOPKeeper.sol";

contract GeneralKeeper is AdminSetting {
    IBOAKeeper private _BOAKeeper;
    IBOHKeeper private _BOHKeeper;
    IBOMKeeper private _BOMKeeper;
    IBOOKeeper private _BOOKeeper;
    IBOPKeeper private _BOPKeeper;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ###############
    // ##   Event   ##
    // ###############

    event SetBOAKeeper(address keeper);

    event SetBOHKeeper(address keeper);

    event SetBOMKeeper(address keeper);

    event SetBOOKeeper(address keeper);

    event SetBOPKeeper(address keeper);

    // ######################
    // ##   AdminSetting   ##
    // ######################

    function setBOAKeeper(address keeper) external onlyGeneralKeeper {
        _BOAKeeper = IBOAKeeper(keeper);
        emit SetBOAKeeper(keeper);
    }

    function setBOHKeeper(address keeper) external onlyGeneralKeeper {
        _BOHKeeper = IBOHKeeper(keeper);
        emit SetBOHKeeper(keeper);
    }

    function setBOMKeeper(address keeper) external onlyGeneralKeeper {
        _BOMKeeper = IBOMKeeper(keeper);
        emit SetBOMKeeper(keeper);
    }

    function setBOOKeeper(address keeper) external onlyGeneralKeeper {
        _BOOKeeper = IBOOKeeper(keeper);
        emit SetBOOKeeper(keeper);
    }

    function setBOPKeeper(address keeper) external onlyGeneralKeeper {
        _BOPKeeper = IBOPKeeper(keeper);
        emit SetBOPKeeper(keeper);
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint8 docType) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.createIA(docType);
    }

    function removeIA(address body) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.removeIA(body);
    }

    function submitIA(address body, bytes32 docHash) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.submitIA(body, docHash);
    }

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.execTagAlong(
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            execDate
        );
    }

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.execDragAlong(
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            execDate
        );
    }

    function acceptAlongDeal(
        address ia,
        address drager,
        bytes32 sn
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.acceptAlongDeal(ia, drager, sn);
    }

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 execDate
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.execFirstRefusal(ia, sn, execDate);
    }

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.acceptFirstRefusalRequest(ia, sn, acceptDate);
    }

    function pushToCoffer(
        bytes32 sn,
        address ia,
        bytes32 hashLock,
        uint256 closingDate
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.pushToCoffer(sn, ia, hashLock, closingDate);
    }

    function closeDeal(
        bytes32 sn,
        address ia,
        uint32 closingDate,
        string hashKey
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.closeDeal(sn, ia, closingDate, hashKey);
    }

    function revokeDeal(
        bytes32 sn,
        address ia,
        string hashKey
    ) external {
        IAdminSetting(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.revokeDeal(sn, ia, hashKey);
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(uint8 title, address addr) external {
        IAdminSetting(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.addTermTemplate(title, addr);
    }

    function createSHA(uint8 docType) external returns (address body) {
        IAdminSetting(_BOHKeeper).setMsgSender(msg.sender);
        body = _BOHKeeper.createSHA(docType);
    }

    function removeSHA(address body) external {
        IAdminSetting(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.removeSHA(body);
    }

    function submitSHA(address body, bytes32 docHash) external {
        IAdminSetting(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.submitSHA(body, docHash);
    }

    function effectiveSHA(address body) external {
        IAdminSetting(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.effectiveSHA(body);
    }

    // ###################
    // ##   BOMKeeper   ##
    // ###################

    function proposeMotion(address ia, uint32 proposeDate) external {
        IAdminSetting(_BOMKeeper).setMsgSender(msg.sender);
        _BOMKeeper.proposeMotion(ia, proposeDate);
    }

    function voteCounting(address ia) external {
        IAdminSetting(_BOMKeeper).setMsgSender(msg.sender);
        _BOMKeeper.voteCounting(ia);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        address againstVoter
    ) external {
        IAdminSetting(_BOMKeeper).setMsgSender(msg.sender);
        _BOMKeeper.requestToBuy(ia, sn, exerciseDate, againstVoter);
    }

    // #################
    // ##  BOOKeeper  ##
    // #################

    function termsTemplate(uint256 index) external returns (address) {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.termsTemplate(index);
    }

    function createOption(
        uint8 typeOfOpt,
        address rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.createOption(
            typeOfOpt,
            rightholder,
            triggerDate,
            exerciseDays,
            closingDays,
            rate,
            parValue,
            paidPar
        );
    }

    function joinOptionAsObligor(bytes32 sn) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.joinOptionAsObligor(sn);
    }

    function releaseObligorFromOption(bytes32 sn, address obligor) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.releaseObligorFromOption(sn, obligor);
    }

    function execOption(bytes32 sn, uint32 exerciseDate) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.execOption(sn, exerciseDate);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.addFuture(sn, shareNumber, paidPar);
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.removeFuture(sn, ft);
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.requestPledge(sn, shareNumber, paidPar);
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.lockOption(sn, hashLock);
    }

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate
    ) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.closeOption(sn, hashKey, closingDate);
    }

    function revokeOption(bytes32 sn, uint32 revokeDate) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.revokeOption(sn, revokeDate);
    }

    function releasePledges(bytes32 sn) external {
        IAdminSetting(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.releasePledges(sn);
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        address creditor,
        address debtor,
        uint256 guaranteedAmt
    ) external {
        IAdminSetting(_BOPKeeper).setMsgSender(msg.sender);
        _BOPKeeper.createPledge(
            createDate,
            shareNumber,
            pledgedPar,
            creditor,
            debtor,
            guaranteedAmt
        );
    }

    function updatePledge(
        bytes32 sn,
        address creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external {
        IAdminSetting(_BOPKeeper).setMsgSender(msg.sender);
        _BOPKeeper.updatePledge(sn, creditor, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn) external {
        IAdminSetting(_BOPKeeper).setMsgSender(msg.sender);
        _BOPKeeper.delPledge(sn);
    }
}
