/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/AdminSetting.sol";

import "../common/config/BOSSetting.sol";
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
import "../common/interfaces/ISigPage.sol";

import "../books/boh/interfaces/IVotingRules.sol";

import "../common/components/EnumsRepo.sol";

contract Bookeeper is
    EnumsRepo,
    BOSSetting,
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

    // ###############
    // ##   Admin   ##
    // ###############

    function setKeeperOfBook(address book, address bookeeper)
        external
        onlyBookeeper
    {
        IAdminSetting(book).setBookeeper(bookeeper);
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(uint8 title, address add) external onlyAdmin {
        termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function createSHA(uint8 docType)
        external
        onlyMember
        returns (address body)
    {
        body = _boh.createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IShareholdersAgreement(body).setTermsTemplate(termsTemplate);
        IShareholdersAgreement(body).setBOS(address(_bos));
        IShareholdersAgreement(body).setBOM(address(_bom));
    }

    function removeSHA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        _boh.removeDoc(body);
    }

    function submitSHA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        _boh.submitSHA(body, docHash);

        IAdminSetting(body).abandonAdmin();
    }

    function effectiveSHA(address body) external onlyPartyOf(body) {
        require(_boh.isSubmitted(body), "SHA not submitted yet");
        // 将之前有效的SHA，撤销其效力
        if (_boh.getTheOne() != address(0))
            ISigPage(_boh.getTheOne()).updateStateOfDoc(5);

        _boh.setPointer(body);

        ISigPage(body).updateStateOfDoc(4);
    }

    // ##################
    // ##    Option    ##
    // ##################

    function execOption(
        bytes32 sn,
        uint256 exerciseDate,
        bytes32 hashLock
    ) external {
        (address rightholder, , , , ) = _boo.getOption(sn);

        require(msg.sender == rightholder, "NOT rightholder");

        require(_boo.stateOfOption(sn) == 1, "option's state is NOT correct");

        uint256 triggerDate = sn.triggerDateOfOpt();
        uint8 exerciseDays = sn.exerciseDaysOfOpt();

        if (now > triggerDate + uint256(exerciseDays) * 86400)
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

    // ################
    // ##   Pledge   ##
    // ################

    function createPledge(
        uint32 createDate,
        bytes32 shareNumber,
        uint256 pledgedPar,
        address creditor,
        uint256 guaranteedAmt
    ) external {
        require(shareNumber.shareholder() == msg.sender, "NOT shareholder");

        _bos.decreaseCleanPar(shareNumber, pledgedPar);

        _bop.createPledge(
            createDate,
            shareNumber,
            pledgedPar,
            creditor,
            guaranteedAmt
        );
    }

    function updatePledge(
        bytes32 sn,
        uint256 pledgedPar,
        uint256 guaranteedAmt
    ) external {
        require(pledgedPar > 0, "ZERO pledgedPar");

        (bytes32 shareNumber, uint256 orgPledgedPar, , ) = _bop.getPledge(sn);

        if (pledgedPar < orgPledgedPar) {
            require(msg.sender == sn.creditor(), "NOT creditor");
            _bos.increaseCleanPar(shareNumber, orgPledgedPar - pledgedPar);
        } else if (pledgedPar > orgPledgedPar) {
            require(msg.sender == shareNumber.shareholder(), "NOT shareholder");
            _bos.decreaseCleanPar(shareNumber, pledgedPar - orgPledgedPar);
        }

        _bop.updatePledge(sn, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn) external {
        require(msg.sender == sn.creditor(), "NOT creditor");

        (bytes32 shareNumber, uint256 pledgedPar, , ) = _bop.getPledge(sn);
        _bos.increaseCleanPar(shareNumber, pledgedPar);

        _bop.delPledge(sn);
    }

    // ###################
    // ##   Agreement   ##
    // ###################

    function createIA(uint8 docType)
        external
        onlyMember
        returns (address body)
    {
        body = _boa.createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IBOSSetting(body).setBOS(address(_bos));
    }

    function removeIA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        _boa.removeDoc(body);
    }

    function submitIA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        _boa.submitDoc(body, docHash);
        // ISigPage(body).submitDoc();
        IAdminSetting(body).abandonAdmin();
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

        require(IAgreement(ia).typeOfIA() != 3, "NOT need to vote");

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
        uint8 typeOfIA = IAgreement(ia).typeOfIA();
        votingType = (typeOfIA == 2 || typeOfIA == 5) ? 2 : (typeOfIA == 3)
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
                parValue.mul(voteAmt).mul(10000) / againstPar / 10000,
                paidPar.mul(voteAmt).mul(10000) / againstPar / 10000
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

        IAgreement(ia).delDeal(sn);

        _bom.turnOverVote(ia, sn.buyer(), turnOverDate);
        _bom.voteCounting(ia, _getVotingType(ia));
    }

    // ##############
    // ##   Deal   ##
    // ##############

    function pushToCoffer(
        bytes32 sn,
        address ia,
        bytes32 hashLock,
        uint256 closingDate
    ) external returns (bool flag) {
        require(_bom.isPassed(ia), "Motion NOT passed");

        (
            uint8 typeOfDeal,
            bytes32 shareNumber,
            ,
            address seller,

        ) = IAgreement(ia).parseSN(sn);

        //交易发起人为卖方或簿记管理人(Bookeeper);
        address sender = msg.sender;
        require(
            (typeOfDeal == 1 && sender == getBookeeper()) || sender == seller,
            "NOT seller or Bookeeper"
        );

        //SHA校验
        if (typeOfDeal > 1) flag = _checkFlag(_termsForShareTransfer, ia, sn);
        else flag = _checkFlag(_termsForCapitalIncrease, ia, sn);

        if (flag) {
            IAgreement(ia).clearDealCP(sn, hashLock, closingDate);
            if (typeOfDeal > 1) _bos.updateShareState(shareNumber, 1);
        }
    }

    function _checkFlag(
        TermTitle[] terms,
        address ia,
        bytes32 sn
    ) private returns (bool flag) {
        uint256 len = terms.length;
        for (uint256 i = 0; i < len; i++) {
            if (getSHA().hasTitle(uint8(terms[i]))) {
                flag = getSHA().termIsExempted(uint8(terms[i]), ia, sn);
                if (!flag) return;
            }
        }
    }

    function closeDeal(
        bytes32 sn,
        address ia,
        uint32 closingDate,
        string hashKey
    ) external currentDate(closingDate) {
        //校验ia是否注册;
        require(_boa.isRegistered(ia), "协议  未注册");

        (
            uint256 unitPrice,
            uint256 parValue,
            uint256 paidPar,
            ,
            ,

        ) = IAgreement(ia).getDeal(sn);

        // address buyer = sn.buyer();

        //交易发起人为买方;
        require(sn.buyer() == msg.sender, "仅 买方  可调用");

        //验证hashKey, 执行Deal
        IAgreement(ia).closeDeal(sn, hashKey);

        bytes32 shareNumber = sn.shareNumber(_bos.snList());

        //释放Share的质押标记(若需)，执行交易
        if (shareNumber > 0) {
            _bos.updateShareState(shareNumber, 0);
            _bos.transferShare(
                shareNumber,
                parValue,
                paidPar,
                sn.buyer(),
                closingDate,
                unitPrice
            );
        } else {
            _bos.issueShare(
                sn.buyer(),
                sn.class(),
                parValue,
                paidPar,
                closingDate, //paidInDeadline
                closingDate, //issueDate
                unitPrice //issuePrice
            );
        }
    }

    function revokeDeal(
        bytes32 sn,
        address ia,
        string hashKey
    ) external {
        require(_boa.isRegistered(ia), "IA NOT registered");

        address sender = msg.sender;
        require(
            (sn.typeOfDeal() == 1 && sender == getBookeeper()) ||
                sender == sn.seller(_bos.snList()),
            "NOT seller or bookeeper"
        );

        IAgreement(ia).revokeDeal(sn, hashKey);

        if (sn.typeOfDeal() > 1)
            _bos.updateShareState(sn.shareNumber(_bos.snList()), 0);
    }
}
