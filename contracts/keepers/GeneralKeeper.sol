// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";
import "../common/access/IAccessControl.sol";

import "./IGeneralKeeper.sol";
import "./IBOAKeeper.sol";
import "./IBODKeeper.sol";
import "./ISHAKeeper.sol";
import "./IBOHKeeper.sol";
import "./IBOMKeeper.sol";
import "./IBOOKeeper.sol";
import "./IBOPKeeper.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {
    IBOAKeeper private _BOAKeeper;
    IBODKeeper private _BODKeeper;
    ISHAKeeper private _SHAKeeper;
    IBOHKeeper private _BOHKeeper;
    IBOMKeeper private _BOMKeeper;
    IBOOKeeper private _BOOKeeper;
    IBOPKeeper private _BOPKeeper;

    // ######################
    // ##   AccessControl   ##
    // ######################

    function setBOAKeeper(address keeper) external onlyManager(1) {
        _BOAKeeper = IBOAKeeper(keeper);
        emit SetBOAKeeper(keeper);
    }

    function setBODKeeper(address keeper) external onlyManager(1) {
        _BODKeeper = IBODKeeper(keeper);
        emit SetBODKeeper(keeper);
    }

    function setBOHKeeper(address keeper) external onlyManager(1) {
        _BOHKeeper = IBOHKeeper(keeper);
        emit SetBOHKeeper(keeper);
    }

    function setBOMKeeper(address keeper) external onlyManager(1) {
        _BOMKeeper = IBOMKeeper(keeper);
        emit SetBOMKeeper(keeper);
    }

    function setBOOKeeper(address keeper) external onlyManager(1) {
        _BOOKeeper = IBOOKeeper(keeper);
        emit SetBOOKeeper(keeper);
    }

    function setBOPKeeper(address keeper) external onlyManager(1) {
        _BOPKeeper = IBOPKeeper(keeper);
        emit SetBOPKeeper(keeper);
    }

    function setSHAKeeper(address keeper) external onlyManager(1) {
        _SHAKeeper = ISHAKeeper(keeper);
        emit SetSHAKeeper(keeper);
    }

    function isKeeper(address caller) external view returns (bool flag) {
        if (
            caller == address(_BOAKeeper) ||
            caller == address(_BODKeeper) ||
            caller == address(_BOHKeeper) ||
            caller == address(_SHAKeeper) ||
            caller == address(_BOMKeeper) ||
            caller == address(_BOOKeeper) ||
            caller == address(_BOPKeeper)
        ) flag = true;
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint8 typeOfIA) external {
        _BOAKeeper.createIA(typeOfIA, _msgSender());
    }

    function removeIA(address body) external {
        _BOAKeeper.removeIA(body, _msgSender());
    }

    function circulateIA(address body) external {
        _BOAKeeper.circulateIA(body, msg.sender);
    }

    function signIA(address ia, bytes32 sigHash) external {
        _BOAKeeper.signIA(ia, _msgSender(), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint32 closingDate
    ) external {
        _BOAKeeper.pushToCoffer(ia, sn, hashLock, closingDate, _msgSender());
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        _BOAKeeper.closeDeal(ia, sn, hashKey, _msgSender());
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        _BOAKeeper.revokeDeal(ia, sn, _msgSender(), hashKey);
    }

    function setPayInAmount(
        uint32 ssn,
        uint64 amount,
        bytes32 hashLock
    ) external onlyManager(1) {
        _BOAKeeper.setPayInAmount(ssn, amount, hashLock);
    }

    function requestPaidInCapital(uint32 ssn, string memory hashKey) external {
        _BOAKeeper.requestPaidInCapital(ssn, hashKey, _msgSender());
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external onlyManager(1) {
        _BOAKeeper.decreaseCapital(ssn, parValue, paidPar);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyManager(1) {
        _BOAKeeper.setMaxQtyOfMembers(max);
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function appointDirector(uint40 candidate, uint8 title) external {
        _BODKeeper.appointDirector(candidate, title, _msgSender());
    }

    function takePosition(uint256 motionId) external {
        _BODKeeper.takePosition(_msgSender(), motionId);
    }

    function removeDirector(uint40 director) external {
        _BODKeeper.removeDirector(director, _msgSender());
    }

    function quitPosition() external {
        _BODKeeper.quitPosition(_msgSender());
    }

    // ==== resolution ====

    function entrustDirectorDelegate(uint40 delegate, uint256 actionId)
        external
    {
        _BODKeeper.entrustDelegate(_msgSender(), delegate, actionId);
    }

    function proposeBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        _BODKeeper.proposeAction(
            actionType,
            targets,
            values,
            params,
            desHash,
            _msgSender()
        );
    }

    function castBoardVote(
        uint256 actionId,
        uint8 attitude,
        bytes32 sigHash
    ) external {
        _BODKeeper.castVote(actionId, attitude, _msgSender(), sigHash);
    }

    function boardVoteCounting(uint256 actionId) external {
        _BODKeeper.voteCounting(actionId, _msgSender());
    }

    function execBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        _BODKeeper.execAction(
            actionType,
            targets,
            values,
            params,
            desHash,
            _msgSender()
        );
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(uint8 title, address addr) external {
        _BOHKeeper.addTermTemplate(title, addr, _msgSender());
    }

    function createSHA(uint8 docType) external {
        _BOHKeeper.createSHA(docType, _msgSender());
    }

    function removeSHA(address body) external {
        _BOHKeeper.removeSHA(body, _msgSender());
    }

    function circulateSHA(address body) external {
        _BOHKeeper.circulateSHA(body, msg.sender);
    }

    function signSHA(address sha, bytes32 sigHash) external {
        _BOHKeeper.signSHA(sha, _msgSender(), sigHash);
    }

    function effectiveSHA(address body) external {
        _BOHKeeper.effectiveSHA(body, _msgSender());
    }

    // ###################
    // ##   BOMKeeper   ##
    // ###################

    function entrustMemberDelegate(uint40 delegate, uint256 motionId) external {
        _BOMKeeper.entrustDelegate(_msgSender(), delegate, motionId);
    }

    function nominateDirector(uint40 candidate) external {
        _BOMKeeper.nominateDirector(candidate, _msgSender());
    }

    function proposeIA(address ia) external {
        _BOMKeeper.proposeIA(ia, _msgSender());
    }

    function proposeGMAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        _BOMKeeper.proposeAction(
            actionType,
            targets,
            values,
            params,
            desHash,
            _msgSender()
        );
    }

    function castGMVote(
        uint256 motionId,
        uint8 attitude,
        bytes32 sigHash
    ) external {
        _BOMKeeper.castVote(motionId, attitude, _msgSender(), sigHash);
    }

    function voteCounting(uint256 motionId) external {
        _BOMKeeper.voteCounting(motionId, _msgSender());
    }

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external returns (uint256) {
        return
            _BOMKeeper.execAction(
                actionType,
                targets,
                values,
                params,
                desHash,
                _msgSender()
            );
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint40 againstVoter
    ) external {
        _BOMKeeper.requestToBuy(ia, sn, againstVoter, _msgSender());
    }

    // #################
    // ##  BOOKeeper  ##
    // #################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    ) external {
        _BOOKeeper.createOption(sn, rightholder, paid, par, _msgSender());
    }

    function execOption(bytes32 sn) external {
        _BOOKeeper.execOption(sn, _msgSender());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        _BOOKeeper.addFuture(sn, shareNumber, paidPar, _msgSender());
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        _BOOKeeper.removeFuture(sn, ft, _msgSender());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        _BOOKeeper.requestPledge(sn, shareNumber, paidPar, _msgSender());
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        _BOOKeeper.lockOption(sn, hashLock, _msgSender());
    }

    function closeOption(bytes32 sn, string memory hashKey) external {
        _BOOKeeper.closeOption(sn, hashKey, _msgSender());
    }

    function revokeOption(bytes32 sn) external {
        _BOOKeeper.revokeOption(sn, _msgSender());
    }

    function releasePledges(bytes32 sn) external {
        _BOOKeeper.releasePledges(sn, _msgSender());
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 pledgedPar,
        uint40 creditor,
        uint64 guaranteedAmt
    ) external {
        _BOPKeeper.createPledge(
            sn,
            shareNumber,
            creditor,
            pledgedPar,
            guaranteedAmt,
            _msgSender()
        );
    }

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external {
        _BOPKeeper.updatePledge(
            sn,
            creditor,
            pledgedPar,
            guaranteedAmt,
            _msgSender()
        );
    }

    // ###################
    // ##   SHAKeeper   ##
    // ###################

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execAlongRight(
            ia,
            sn,
            false,
            shareNumber,
            paid,
            par,
            _msgSender(),
            sigHash
        );
    }

    function acceptTagAlong(
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        _SHAKeeper.acceptAlongDeal(ia, sn, _msgSender(), sigHash);
    }

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execAlongRight(
            ia,
            sn,
            true,
            shareNumber,
            paid,
            par,
            _msgSender(),
            sigHash
        );
    }

    function acceptDragAlong(
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        _SHAKeeper.acceptAlongDeal(ia, sn, _msgSender(), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execAntiDilution(ia, sn, shareNumber, _msgSender(), sigHash);
    }

    function takeGiftShares(address ia, bytes32 sn) external {
        _SHAKeeper.takeGiftShares(ia, sn, _msgSender());
        _BOAKeeper.transferTargetShare(ia, sn);
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execFirstRefusal(ia, sn, _msgSender(), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfOrg,
        uint16 ssnOfFR,
        bytes32 sigHash
    ) external {
        _SHAKeeper.acceptFirstRefusal(
            ia,
            snOfOrg,
            ssnOfFR,
            _msgSender(),
            sigHash
        );
    }
}
