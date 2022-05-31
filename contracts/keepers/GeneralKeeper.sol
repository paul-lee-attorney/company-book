/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../common/access/AccessControl.sol";
import "../common/access/interfaces/IAccessControl.sol";

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

    constructor(uint32 bookeeper, address regCenter) public {
        init(_msgSender(), bookeeper, regCenter);
    }

    // ###############
    // ##   Event   ##
    // ###############

    event SetBOAKeeper(address keeper);

    event SetBOHKeeper(address keeper);

    event SetBOMKeeper(address keeper);

    event SetBOOKeeper(address keeper);

    event SetBOPKeeper(address keeper);

    event SetKeepers(address target, address keeper);

    // ######################
    // ##   AccessControl   ##
    // ######################

    function setBOAKeeper(address keeper) external onlyDirectKeeper {
        _BOAKeeper = IBOAKeeper(keeper);
        IAccessControl(keeper).init(getOwner(), _rc.userNo(this), address(_rc));
        emit SetBOAKeeper(keeper);
    }

    function setBOHKeeper(address keeper) external onlyDirectKeeper {
        _BOHKeeper = IBOHKeeper(keeper);
        IAccessControl(keeper).init(getOwner(), _rc.userNo(this), address(_rc));
        emit SetBOHKeeper(keeper);
    }

    function setBOMKeeper(address keeper) external onlyDirectKeeper {
        _BOMKeeper = IBOMKeeper(keeper);
        IAccessControl(keeper).init(getOwner(), _rc.userNo(this), address(_rc));
        emit SetBOMKeeper(keeper);
    }

    function setBOOKeeper(address keeper) external onlyDirectKeeper {
        _BOOKeeper = IBOOKeeper(keeper);
        IAccessControl(keeper).init(getOwner(), _rc.userNo(this), address(_rc));
        emit SetBOOKeeper(keeper);
    }

    function setBOPKeeper(address keeper) external onlyDirectKeeper {
        _BOPKeeper = IBOPKeeper(keeper);
        IAccessControl(keeper).init(getOwner(), _rc.userNo(this), address(_rc));
        emit SetBOPKeeper(keeper);
    }

    function setKeepers(address target, address keeper)
        external
        onlyDirectKeeper
    {
        IRoles(target).grantRole(KEEPERS, _rc.userNo(keeper));
        emit SetKeepers(target, keeper);
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint8 docType) external {
        _BOAKeeper.createIA(docType, _msgSender());
    }

    function removeIA(address body, uint32 sigDate) external {
        _BOAKeeper.removeIA(body, _msgSender(), sigDate);
    }

    function submitIA(
        address body,
        uint32 submitDate,
        bytes32 docHash
    ) external {
        _BOAKeeper.submitIA(body, submitDate, docHash, _msgSender());
    }

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 sigDate,
        bytes32 sigHash
    ) external {
        _BOAKeeper.execTagAlong(
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            _msgSender(),
            sigDate,
            sigHash
        );
    }

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate,
        bytes32 sigHash
    ) external {
        _BOAKeeper.execDragAlong(
            ia,
            sn,
            shareNumber,
            parValue,
            paidPar,
            _msgSender(),
            execDate,
            sigHash
        );
    }

    function acceptTagAlong(
        address ia,
        bytes32 sn,
        uint32 drager,
        uint32 sigDate,
        bytes32 sigHash
    ) external {
        _BOAKeeper.acceptAlongDeal(
            ia,
            sn,
            drager,
            false,
            _msgSender(),
            sigDate,
            sigHash
        );
    }

    function acceptDragAlong(
        bytes32 snOfOpt,
        bytes32 shareNumber,
        uint32 sigDate
    ) external {
        _BOAKeeper.acceptDragAlong(snOfOpt, shareNumber, _msgSender(), sigDate);
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint32 execDate,
        bytes32 sigHash
    ) external {
        _BOAKeeper.execFirstRefusal(ia, sn, _msgSender(), execDate, sigHash);
    }

    function acceptFirstRefusalRequest(
        address ia,
        bytes32 sn,
        uint32 acceptDate
    ) external {
        _BOAKeeper.acceptFirstRefusalRequest(ia, sn, acceptDate, _msgSender());
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint256 closingDate,
        uint32 sigDate
    ) external {
        _BOAKeeper.pushToCoffer(
            ia,
            sn,
            hashLock,
            closingDate,
            _msgSender(),
            sigDate
        );
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        uint32 closingDate,
        string hashKey
    ) external {
        _BOAKeeper.closeDeal(ia, sn, closingDate, hashKey, _msgSender());
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string hashKey
    ) external {
        _BOAKeeper.revokeDeal(ia, sn, hashKey, _msgSender());
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

    function submitSHA(
        address body,
        uint32 submitDate,
        bytes32 docHash
    ) external {
        _BOHKeeper.submitSHA(body, _msgSender(), submitDate, docHash);
    }

    function effectiveSHA(address body) external {
        _BOHKeeper.effectiveSHA(body, _msgSender());
    }

    // ###################
    // ##   BOMKeeper   ##
    // ###################

    function proposeMotion(address ia, uint32 proposeDate) external {
        _BOMKeeper.proposeMotion(ia, proposeDate, _msgSender());
    }

    function supportMotion(
        address ia,
        uint32 sigDate,
        bytes32 sigHash
    ) external {
        _BOMKeeper.supportMotion(ia, _msgSender(), sigDate, sigHash);
    }

    function againstMotion(
        address ia,
        uint32 sigDate,
        bytes32 sigHash
    ) external {
        _BOMKeeper.againstMotion(ia, _msgSender(), sigDate, sigHash);
    }

    function voteCounting(address ia) external {
        _BOMKeeper.voteCounting(ia, _msgSender());
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        uint32 againstVoter
    ) external {
        _BOMKeeper.requestToBuy(
            ia,
            sn,
            exerciseDate,
            againstVoter,
            _msgSender()
        );
    }

    // #################
    // ##  BOOKeeper  ##
    // #################

    function termsTemplate(uint256 index) external returns (address) {
        _BOOKeeper.termsTemplate(index, _msgSender());
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

    function releaseObligorFromOption(bytes32 sn, uint32 obligor) external {
        _BOOKeeper.releaseObligorFromOption(sn, obligor, _msgSender());
    }

    function execOption(bytes32 sn, uint32 exerciseDate) external {
        _BOOKeeper.execOption(sn, exerciseDate, _msgSender());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external {
        _BOOKeeper.addFuture(sn, shareNumber, paidPar, _msgSender());
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        _BOOKeeper.removeFuture(sn, ft, _msgSender());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 paidPar
    ) external {
        _BOOKeeper.requestPledge(sn, shareNumber, paidPar, _msgSender());
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        _BOOKeeper.lockOption(sn, hashLock, _msgSender());
    }

    function closeOption(
        bytes32 sn,
        string hashKey,
        uint32 closingDate
    ) external {
        _BOOKeeper.closeOption(sn, hashKey, closingDate, _msgSender());
    }

    function revokeOption(bytes32 sn, uint32 revokeDate) external {
        _BOOKeeper.revokeOption(sn, revokeDate, _msgSender());
    }

    function releasePledges(bytes32 sn) external {
        _BOOKeeper.releasePledges(sn, _msgSender());
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
        _BOPKeeper.createPledge(
            createDate,
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
        uint32 creditor,
        uint256 pledgedPar,
        uint256 guaranteedAmt
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
}
