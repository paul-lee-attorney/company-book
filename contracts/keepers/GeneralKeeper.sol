/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

import "../common/access/AccessControl.sol";
import "../common/access/IAccessControl.sol";

import "./IBOAKeeper.sol";
import "./IBODKeeper.sol";
import "./ISHAKeeper.sol";
import "./IBOHKeeper.sol";
import "./IBOMKeeper.sol";
import "./IBOOKeeper.sol";
import "./IBOPKeeper.sol";

contract GeneralKeeper is AccessControl {
    IBOAKeeper private _BOAKeeper;
    IBODKeeper private _BODKeeper;
    ISHAKeeper private _SHAKeeper;
    IBOHKeeper private _BOHKeeper;
    IBOMKeeper private _BOMKeeper;
    IBOOKeeper private _BOOKeeper;
    IBOPKeeper private _BOPKeeper;

    // ###############
    // ##   Event   ##
    // ###############

    event SetBOAKeeper(address keeper);

    event SetBODKeeper(address keeper);

    event SetSHAKeeper(address keeper);

    event SetBOHKeeper(address keeper);

    event SetBOMKeeper(address keeper);

    event SetBOOKeeper(address keeper);

    event SetBOPKeeper(address keeper);

    // event SetKeepers(address target, address keeper);

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

    function grantKeepers(address target) external onlyManager(1) {
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_BOAKeeper));
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_BODKeeper));
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_BOHKeeper));
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_BOMKeeper));
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_BOOKeeper));
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_BOPKeeper));
        IAccessControl(target).grantRole(KEEPERS, _rc.userNo(_SHAKeeper));
    }

    // function setKeepers(address target, address keeper)
    //     external
    //     onlyManager(1)
    // {
    //     IRoles(target).grantRole(KEEPERS, keeper);
    //     emit SetKeepers(target, keeper);
    // }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint8 typeOfIA) external {
        _BOAKeeper.createIA(typeOfIA, msg.sender);
    }

    function removeIA(address body) external {
        _BOAKeeper.removeIA(body, _msgSender());
    }

    function circulateIA(address body) external {
        _BOAKeeper.circulateIA(body, _msgSender());
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
        string hashKey
    ) external {
        _BOAKeeper.closeDeal(ia, sn, hashKey, _msgSender());
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string hashKey
    ) external {
        _BOAKeeper.revokeDeal(ia, sn, _msgSender(), hashKey);
    }

    // ###################
    // ##   SHAKeeper   ##
    // ###################

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 parValue,
        uint64 paidPar,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execAlongRight(
            ia,
            sn,
            false,
            shareNumber,
            parValue,
            paidPar,
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
        uint64 parValue,
        uint64 paidPar,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execAlongRight(
            ia,
            sn,
            true,
            shareNumber,
            parValue,
            paidPar,
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

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function addTermTemplate(uint8 title, address addr) external {
        _BOHKeeper.addTermTemplate(title, addr, _msgSender());
    }

    function createSHA(uint8 docType) external {
        _BOHKeeper.createSHA(docType, msg.sender);
    }

    function removeSHA(address body) external {
        _BOHKeeper.removeSHA(body, _msgSender());
    }

    function circulateSHA(address body) external {
        _BOHKeeper.circulateSHA(body, _msgSender());
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

    function proposeMotion(address ia) external {
        _BOMKeeper.proposeMotion(ia, _msgSender());
    }

    function castVote(
        address ia,
        uint8 attitude,
        bytes32 sigHash
    ) external {
        _BOMKeeper.castVote(ia, attitude, _msgSender(), sigHash);
    }

    function voteCounting(address ia) external {
        _BOMKeeper.voteCounting(ia, _msgSender());
    }

    // function execAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash
    // ) external returns (uint256) {
    //     _BOMKeeper.execAction(
    //         actionType,
    //         targets,
    //         params,
    //         desHash,
    //         _msgSender()
    //     );
    // }

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
        uint8 typeOfOpt,
        uint40 rightholder,
        uint32 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint32 rate,
        uint64 parValue,
        uint64 paidPar
    ) external {
        _BOOKeeper.createOption(
            typeOfOpt,
            rightholder,
            triggerDate,
            exerciseDays,
            closingDays,
            rate,
            parValue,
            paidPar,
            _msgSender()
        );
    }

    function joinOptionAsObligor(bytes32 sn) external {
        _BOOKeeper.joinOptionAsObligor(sn, _msgSender());
    }

    function releaseObligorFromOption(bytes32 sn, uint40 obligor) external {
        _BOOKeeper.releaseObligorFromOption(sn, obligor, _msgSender());
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

    function closeOption(bytes32 sn, string hashKey) external {
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
        bytes32 shareNumber,
        uint64 pledgedPar,
        uint40 creditor,
        uint40 debtor,
        uint64 guaranteedAmt
    ) external {
        _BOPKeeper.createPledge(
            shareNumber,
            pledgedPar,
            creditor,
            debtor,
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

    function delPledge(bytes32 sn) external {
        _BOPKeeper.delPledge(sn, _msgSender());
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function appointDirector(uint40 candidate, uint8 title) external {
        _BODKeeper.appointDirector(candidate, title, _msgSender());
    }

    function removeDirector(uint40 director) external {
        _BODKeeper.removeDirector(director, _msgSender());
    }

    function quitPosition() external {
        _BODKeeper.quitPosition(_msgSender());
    }

    function nominateDirector(uint40 candidate) external {
        _BODKeeper.nominateDirector(candidate, _msgSender());
    }

    function takePosition(uint256 motionId) external {
        _BODKeeper.takePosition(_msgSender(), motionId);
    }
}
