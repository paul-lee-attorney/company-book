/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/access/AccessControl.sol";
import "../common/access/interfaces/IAccessControl.sol";
import "../common/utils/interfaces/IContext.sol";

import "./interfaces/IBOAKeeper.sol";
import "./interfaces/IBOHKeeper.sol";
import "./interfaces/IBOMKeeper.sol";
import "./interfaces/IBOOKeeper.sol";
import "./interfaces/IBOPKeeper.sol";

contract GeneralKeeper is AccessControl {
    IBOAKeeper private _BOAKeeper;
    IBOHKeeper private _BOHKeeper;
    IBOMKeeper private _BOMKeeper;
    IBOOKeeper private _BOOKeeper;
    IBOPKeeper private _BOPKeeper;

    // constructor(uint32 bookeeper) public {
    //     init(msg.sender, bookeeper);
    // }

    // ###############
    // ##   Event   ##
    // ###############

    event SetBOAKeeper(address keeper);

    event SetBOHKeeper(address keeper);

    event SetBOMKeeper(address keeper);

    event SetBOOKeeper(address keeper);

    event SetBOPKeeper(address keeper);

    // ######################
    // ##   AccessControl   ##
    // ######################

    function setBOAKeeper(address keeper) external onlyDirectKeeper {
        _BOAKeeper = IBOAKeeper(keeper);
        emit SetBOAKeeper(keeper);
    }

    function setBOHKeeper(address keeper) external onlyDirectKeeper {
        _BOHKeeper = IBOHKeeper(keeper);
        emit SetBOHKeeper(keeper);
    }

    function setBOMKeeper(address keeper) external onlyDirectKeeper {
        _BOMKeeper = IBOMKeeper(keeper);
        emit SetBOMKeeper(keeper);
    }

    function setBOOKeeper(address keeper) external onlyDirectKeeper {
        _BOOKeeper = IBOOKeeper(keeper);
        emit SetBOOKeeper(keeper);
    }

    function setBOPKeeper(address keeper) external onlyDirectKeeper {
        _BOPKeeper = IBOPKeeper(keeper);
        emit SetBOPKeeper(keeper);
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint8 docType) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.createIA(docType);
    }

    function removeIA(address body) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.removeIA(body);
    }

    function submitIA(
        address body,
        uint32 submitDate,
        bytes32 docHash
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.submitIA(body, submitDate, docHash);
    }

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
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
        IContext(_BOAKeeper).setMsgSender(msg.sender);
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
        uint32 drager,
        bytes32 sn
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.acceptAlongDeal(ia, drager, sn);
    }

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 execDate
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.execFirstRefusal(ia, sn, execDate);
    }

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.acceptFirstRefusalRequest(ia, sn, acceptDate);
    }

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint256 closingDate
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.pushToCoffer(ia, sn, hashLock, closingDate);
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        uint32 closingDate,
        string hashKey
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.closeDeal(ia, sn, closingDate, hashKey);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string hashKey
    ) external {
        IContext(_BOAKeeper).setMsgSender(msg.sender);
        _BOAKeeper.revokeDeal(ia, sn, hashKey);
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(uint8 title, address addr) external {
        IContext(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.addTermTemplate(title, addr);
    }

    function createSHA(uint8 docType) external {
        IContext(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.createSHA(docType);
    }

    function removeSHA(address body) external {
        IContext(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.removeSHA(body);
    }

    function submitSHA(address body, bytes32 docHash) external {
        IContext(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.submitSHA(body, docHash);
    }

    function effectiveSHA(address body) external {
        IContext(_BOHKeeper).setMsgSender(msg.sender);
        _BOHKeeper.effectiveSHA(body);
    }

    // ###################
    // ##   BOMKeeper   ##
    // ###################

    function proposeMotion(address ia, uint32 proposeDate) external {
        IContext(_BOMKeeper).setMsgSender(msg.sender);
        _BOMKeeper.proposeMotion(ia, proposeDate);
    }

    function voteCounting(address ia) external {
        IContext(_BOMKeeper).setMsgSender(msg.sender);
        _BOMKeeper.voteCounting(ia);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        uint32 againstVoter
    ) external {
        IContext(_BOMKeeper).setMsgSender(msg.sender);
        _BOMKeeper.requestToBuy(ia, sn, exerciseDate, againstVoter);
    }

    // #################
    // ##  BOOKeeper  ##
    // #################

    function termsTemplate(uint256 index) external returns (address) {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.termsTemplate(index);
    }

    function createOption(
        uint8 typeOfOpt,
        uint32 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 rate,
        uint256 parValue,
        uint256 paidPar
    ) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
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
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.joinOptionAsObligor(sn);
    }

    function releaseObligorFromOption(bytes32 sn, uint32 obligor) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.releaseObligorFromOption(sn, obligor);
    }

    function execOption(bytes32 sn, uint32 exerciseDate) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.execOption(sn, exerciseDate);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.addFuture(sn, shareNumber, paidPar);
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.removeFuture(sn, ft);
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.requestPledge(sn, shareNumber, paidPar);
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.lockOption(sn, hashLock);
    }

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate
    ) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.closeOption(sn, hashKey, closingDate);
    }

    function revokeOption(bytes32 sn, uint32 revokeDate) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.revokeOption(sn, revokeDate);
    }

    function releasePledges(bytes32 sn) external {
        IContext(_BOOKeeper).setMsgSender(msg.sender);
        _BOOKeeper.releasePledges(sn);
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        uint32 creditor,
        uint32 debtor,
        uint256 guaranteedAmt
    ) external {
        IContext(_BOPKeeper).setMsgSender(msg.sender);
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
        uint32 creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external {
        IContext(_BOPKeeper).setMsgSender(msg.sender);
        _BOPKeeper.updatePledge(sn, creditor, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn) external {
        IContext(_BOPKeeper).setMsgSender(msg.sender);
        _BOPKeeper.delPledge(sn);
    }
}
