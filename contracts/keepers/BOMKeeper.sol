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
        require(
            _boa.isRegistered(ia),
            "Investment Agreement is NOT registered"
        );

        require(typeOfIA(ia) != 3, "NOT need to vote");

        bytes32 rule = IVotingRules(
            getSHA().getTerm(uint8(TermTitle.VOTING_RULES))
        ).rules(_getVotingType(ia));

        _bom.proposeMotion(ia, proposeDate + uint32(rule.votingDays()) * 86400);
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

    function voteCounting(address ia) external onlyPartyOf(ia) {
        require(_bom.isProposed(ia), "NOT proposed");
        require(_bom.getState(ia) == 1, "NOT in voting");
        require(now > _bom.getVotingDeadline(ia), "voting NOT end");

        uint8 votingType = _getVotingType(ia);

        require(votingType > 0, "NOT need to vote");

        _bom.voteCounting(ia, votingType);
    }

    function replaceRejectedDeal(
        address ia,
        bytes32 sn,
        uint32 exerciseDate
    ) external currentDate(exerciseDate) {
        require(IAgreement(ia).isDeal(sn), "deal NOT exist");
        require(_bom.getState(ia) == 4, "agianst NO need to buy");

        (, , , uint32 closingDate, , ) = IAgreement(ia).getDeal(sn);
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

        require(sn.typeOfDeal() == 2, "NOT a 3rd party ST Deal");
        require(
            msg.sender == sn.seller(_bos.snList()),
            "NOT Seller of the Deal"
        );

        _splitDeal(ia, sn);
    }

    function _splitDeal(address ia, bytes32 sn) private {
        (, uint256 parValue, uint256 paidPar, , , ) = IAgreement(ia).getDeal(
            sn
        );

        (address[] memory buyers, uint256 againstPar) = _bom.getNay(ia);

        // uint256 len = buyers.length;

        for (uint256 i = 0; i < buyers.length; i++) {
            (, , uint256 voteAmt) = _bom.getVote(ia, buyers[i]);
            IAgreement(ia).splitDeal(
                sn,
                buyers[i],
                parValue.mul(voteAmt).div(againstPar),
                paidPar.mul(voteAmt).div(againstPar)
            );
        }
    }

    function turnOverAgainstVote(
        address ia,
        bytes32 sn,
        uint32 turnOverDate
    ) external currentDate(turnOverDate) {
        require(sn.typeOfDeal() == 4, "NOT a replaced deal");

        require(ISigPage(ia).sigDate(sn.buyer()) == 0, "already SIGNED deal");

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

        _bom.turnOverVote(ia, sn.buyer(), turnOverDate);
        _bom.voteCounting(ia, _getVotingType(ia));
    }
}
