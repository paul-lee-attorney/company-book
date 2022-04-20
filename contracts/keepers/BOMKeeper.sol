/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/BOHSetting.sol";
import "../common/config/BOASetting.sol";
import "../common/config/BOMSetting.sol";

import "../common/lib/SafeMath.sol";
import "../common/lib/serialNumber/DealSNParser.sol";
import "../common/lib/serialNumber/VotingRuleParser.sol";

import "../common/interfaces/IAgreement.sol";
import "../common/interfaces/ISigPage.sol";

import "../books/boh/interfaces/IVotingRules.sol";

import "../books/boa/AgreementCalculator.sol";

import "../common/components/EnumsRepo.sol";

contract BOMKeeper is
    AgreementCalculator,
    BOASetting,
    BOMSetting,
    BOHSetting,
    EnumsRepo
{
    using SafeMath for uint256;
    using DealSNParser for bytes32;
    using VotingRuleParser for bytes32;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(msg.sender), "NOT Party of Doc");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    function proposeMotion(address ia, uint32 proposeDate)
        external
        onlyPartyOf(ia)
        currentDate(proposeDate)
    {
        _bom.proposeMotion(ia, proposeDate);
    }

    function voteCounting(address ia) external onlyPartyOf(ia) {
        _bom.voteCounting(ia);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint32 exerciseDate,
        address againstVoter,
        uint256 parValue,
        uint256 paidPar
    ) external currentDate(exerciseDate) {
        require(IAgreement(ia).isDeal(sn.sequenceOfDeal()), "deal NOT exist");
        require(sn.typeOfDeal() == 2, "NOT a 3rd party ST Deal");
        require(
            msg.sender == sn.sellerOfDeal(_bos.snList()),
            "NOT Seller of the Deal"
        );

        (
            ,
            ,
            uint256 orgParValue,
            uint256 orgPaidPar,
            uint32 closingDate,
            ,

        ) = IAgreement(ia).getDeal(sn.sequenceOfDeal());
        require(exerciseDate < closingDate, "MISSED closing date");

        bytes32 rule = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        ).rules(_getVotingType(ia));

        require(
            exerciseDate <
                _bom.getVotingDeadline(ia) +
                    uint32(rule.execDaysForPutOpt()) *
                    86400,
            "MISSED execute deadline"
        );

        uint256 ratio = _ratioOfNay(ia, againstVoter);

        require(
            parValue > 0 && parValue <= ((orgParValue * ratio) / 10000),
            "parValue overflow"
        );

        require(
            paidPar > 0 && paidPar <= ((orgPaidPar * ratio) / 10000),
            "paidPar overflow"
        );

        IAgreement(ia).splitDeal(
            sn.sequenceOfDeal(),
            againstVoter,
            parValue,
            paidPar
        );
    }

    function _ratioOfNay(address ia, address againstVoter)
        private
        view
        returns (uint256)
    {
        require(_bom.getState(ia) == 4, "agianst NO need to buy");

        (, uint256 againstPar) = _bom.getNay(ia);
        (bool attitude, , uint256 amount) = _bom.getVote(ia, againstVoter);

        require(againstPar > 0, "ZERO againstPar");
        require(!attitude && amount > 0, "NOT NAY voter");

        return ((amount * 10000) / againstPar);
    }

    function _getVotingType(address ia)
        private
        view
        returns (uint8 votingType)
    {
        uint8 typeOfAgreement = typeOfIA(ia);
        votingType = (typeOfAgreement == 2 || typeOfAgreement == 5)
            ? 2
            : (typeOfAgreement == 3)
            ? 0
            : 1;
    }

    function turnOverAgainstVote(
        address ia,
        bytes32 sn,
        uint32 turnOverDate
    ) external currentDate(turnOverDate) {
        require(sn.typeOfDeal() == 4, "NOT a replaced deal");

        require(
            ISigPage(ia).sigDate(sn.buyerOfDeal()) == 0,
            "already SIGNED deal"
        );

        require(
            msg.sender == sn.sellerOfDeal(_bos.snList()),
            "NOT Seller of the Deal"
        );

        bytes32 rule = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        ).rules(_getVotingType(ia));

        require(
            turnOverDate >
                _bom.getVotingDeadline(ia) +
                    uint32(
                        rule.execDaysForPutOpt() + rule.turnOverDaysForFuture()
                    ) *
                    86400,
            "signe deadline NOT reached"
        );

        IAgreement(ia).restoreDeal(sn.preSNOfDeal());

        _bom.turnOverVote(ia, sn.buyerOfDeal(), turnOverDate);
        _bom.voteCounting(ia);
    }
}
