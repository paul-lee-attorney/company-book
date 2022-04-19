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

import "../common/lib/SafeMath.sol";
import "../common/lib/serialNumber/ShareSNParser.sol";
import "../common/lib/serialNumber/PledgeSNParser.sol";
import "../common/lib/serialNumber/DealSNParser.sol";
import "../common/lib/serialNumber/OptionSNParser.sol";
import "../common/lib/serialNumber/VotingRuleParser.sol";

import "../common/interfaces/IBOSSetting.sol";
import "../common/interfaces/IAgreement.sol";
import "../common/interfaces/IAdminSetting.sol";
import "../common/interfaces/ISigPage.sol";

import "../books/boh/interfaces/IVotingRules.sol";
import "../books/boa/AgreementCalculator.sol";

import "../common/components/EnumsRepo.sol";

contract BOOKeeper is
    EnumsRepo,
    AgreementCalculator,
    BOASetting,
    BOHSetting,
    BOMSetting,
    BOPSetting,
    BOOSetting
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

    // ##################
    // ##    Option    ##
    // ##################

    function execOption(
        bytes32 sn,
        uint32 exerciseDate,
        bytes32 hashLock
    ) external {
        (address rightholder, , , , ) = _boo.getOption(sn);

        require(msg.sender == rightholder, "NOT rightholder");

        require(_boo.stateOfOption(sn) == 1, "option's state is NOT correct");

        uint32 triggerDate = sn.triggerDateOfOpt();
        uint8 exerciseDays = sn.exerciseDaysOfOpt();

        if (now > triggerDate + uint32(exerciseDays) * 86400)
            _boo.setState(sn, 3); // option expired
        else if (now >= triggerDate) _boo.setState(sn, 2);

        _boo.execOption(sn, exerciseDate, hashLock);
    }

    function closeOption(bytes32 sn, bytes32 hashKey) external {
        require(msg.sender == sn.obligorOfOpt(), "NOT obligor of the Option");

        (, uint256 closingDate, , , ) = _boo.getOption(sn);
        require(now <= closingDate, "LATER than closingDeadline");

        _boo.closeOption(sn, hashKey);
    }
}
