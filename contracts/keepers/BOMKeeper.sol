/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../books/boa/IInvestmentAgreement.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/SHASetting.sol";

import "../common/lib/SNParser.sol";

import "../common/components/ISigPage.sol";

import "../common/lib/EnumsRepo.sol";

import "./IBOMKeeper.sol";

contract BOMKeeper is
    IBOMKeeper,
    BOASetting,
    BODSetting,
    BOMSetting,
    SHASetting,
    BOOSetting,
    BOSSetting
{
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body, uint40 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    modifier notPartyOf(address body, uint40 caller) {
        require(!ISigPage(body).isParty(caller), "Party has no voting right");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    function authorizeToPropose(
        uint40 caller,
        uint40 delegate,
        uint256 actionId
    ) external onlyManager(1) memberExist(caller) {
        _bom.authorizeToPropose(caller, delegate, actionId);
    }

    function proposeMotion(address ia, uint40 caller)
        external
        onlyManager(1)
        memberExist(caller)
        onlyPartyOf(ia, caller)
    {
        require(
            _boa.currentState(ia) == uint8(EnumsRepo.BODStates.Established),
            "InvestmentAgreement not on Established"
        );

        require(
            _boa.reviewDeadlineBNOf(ia) < block.number,
            "InvestmentAgreement not passed review procesedure"
        );

        require(
            _boa.votingDeadlineBNOf(ia) >= block.number,
            "missed votingDeadlineBN"
        );

        bytes32 vr = _getSHA().votingRules(_boa.typeOfIA(ia));

        if (vr.ratioHeadOfVR() > 0 || vr.ratioAmountOfVR() > 0)
            _bom.proposeMotion(ia, caller);

        _boa.pushToNextState(ia, caller);
    }

    // function proposeAction(
    //     uint8 actionType,
    //     address[] target,
    //     bytes32[] params,
    //     bytes32 desHash,
    //     uint40 submitter
    // ) external onlyManager(1) memberExist(submitter) {
    //     _bom.proposeAction(actionType, target, params, desHash, submitter);
    // }

    function castVote(
        address ia,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) notPartyOf(ia, caller) {
        require(_bos.isMember(caller), "not a shareholder");
        _bom.castVote(uint256(ia), attitude, caller, sigHash);
    }

    function voteCounting(address ia, uint40 caller)
        external
        onlyManager(1)
        onlyPartyOf(ia, caller)
    {
        _bom.voteCounting(uint256(ia));
        _boa.pushToNextState(ia, caller);
    }

    // function execAction(
    //     uint8 actionType,
    //     address[] targets,
    //     bytes32[] params,
    //     bytes32 desHash,
    //     uint40 caller
    // ) external returns (uint256) {
    //     require(_bod.isDirector(caller), "caller is not a Director");
    //     require(!_rc.isContract(caller), "caller is not an EOA");
    //     return _bom.execAction(actionType, targets, params, desHash);
    // }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint40 againstVoter,
        uint40 caller
    ) external onlyManager(1) {
        require(
            _bom.state(uint256(ia)) ==
                uint8(EnumsRepo.StateOfMotion.Rejected_ToBuy),
            "agianst NO need to buy"
        );

        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequence()
        );

        require(caller == shareNumber.shareholder(), "NOT Seller of the Deal");

        uint32 unitPrice = IInvestmentAgreement(ia).unitPrice(sn.sequence());
        uint32 closingDate = IInvestmentAgreement(ia).closingDate(
            sn.sequence()
        );

        (uint64 parValue, uint64 paidPar) = _bom.requestToBuy(ia, sn);

        uint8 closingDays = uint8(
            (closingDate - uint32(block.number) + 12 * _rc.blocksPerHour()) /
                (24 * _rc.blocksPerHour())
        );

        bytes32 snOfOpt = _boo.createOption(
            uint8(EnumsRepo.TypeOfOption.Put_Price),
            caller,
            againstVoter,
            uint32(block.number),
            1,
            closingDays,
            unitPrice,
            parValue,
            paidPar
        );

        _boo.execOption(snOfOpt.shortOfOpt());
        _boo.addFuture(snOfOpt.shortOfOpt(), shareNumber, parValue, paidPar);
    }
}
