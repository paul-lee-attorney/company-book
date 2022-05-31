/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./interfaces/IInvestmentAgreement.sol";
import "./interfaces/IInvestmentAgreementCalculator.sol";

import "../boh/terms/interfaces/IAlongs.sol";

import "../boh/ShareholdersAgreement.sol";

import "../../common/components/BookOfDocuments.sol";
// import "../../common/components/EnumsRepo.sol";

import "../../common/ruting/SHASetting.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";

import "../../common/components/interfaces/ISigPage.sol";

contract BookOfIA is BookOfDocuments, SHASetting {
    using SNParser for bytes32;

    IInvestmentAgreementCalculator private _agrmtCal;

    struct Amt {
        uint256 selAmt;
        uint256 buyAmt;
        uint256 orgAmt;
        uint256 rstAmt;
    }

    // IA address => group => Amt
    mapping(address => mapping(uint16 => Amt)) private _mockResults;

    // IA address => groups
    mapping(address => uint16[]) public groupsConcerned;

    // IA address => group => bool
    mapping(address => mapping(uint16 => bool)) public isConcernedGroup;

    struct TopGroup {
        uint16 groupNum;
        uint256 amount;
        bool isOrgController;
        uint256 netIncreasedAmt;
        uint256 shareRatio;
    }

    // IA address => topGroup
    mapping(address => TopGroup) private _topGroups;

    // constructor(
    //     string _bookName,
    //     uint32 _owner,
    //     uint32 _bookeeper,
    //     address _rc
    // ) public BookOfDocuments(_bookName, _owner, _bookeeper, _rc) {}

    //##############
    //##  Event   ##
    //##############

    event SetAgreementCalculator(address indexed calculator);

    event MockDeals(address indexed ia);

    event CalculateResult(
        address indexed ia,
        uint16 topGroup,
        uint256 topAmt,
        bool isOrgController,
        uint256 shareRatio
    );

    event AddAlongDeal(
        address ia,
        uint16 follower,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar
    );

    event AcceptAlongDeal(address ia, address drager, bytes32 sn);

    //#################
    //##  Modifier   ##
    //#################

    //#################
    //##  Write I/O  ##
    //#################

    function setAgreementCalculator(address cal) external onlyOwner {
        _agrmtCal = IInvestmentAgreementCalculator(cal);
        emit SetAgreementCalculator(cal);
    }

    function submitIA(
        address ia,
        uint32 submitter,
        uint32 submitDate,
        bytes32 docHash
    ) external onlyDirectKeeper {
        submitDoc(ia, submitter, submitDate, docHash);
        bool basedOnPar = _getSHA()
            .votingRules(_agrmtCal.typeOfIA(ia))
            .basedOnParOfVR();
        _mockDeals(ia, basedOnPar);
        _calculateResult(ia, basedOnPar);
    }

    function _addGroup(address ia, uint16 group) private {
        if (!isConcernedGroup[ia][group]) {
            isConcernedGroup[ia][group] = true;
            groupsConcerned[ia].push(group);
        }
    }

    function _mockDeals(address ia, bool basedOnPar) private {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        // uint16[] storage groups = groupsConcerned[ia];

        for (uint256 i = 0; i < len; i++) {
            bytes32 sn = dealsList[i];

            uint256 amount;
            if (basedOnPar)
                (, amount, , , ) = IInvestmentAgreement(ia).getDeal(
                    sn.sequenceOfDeal()
                );
            else
                (, , amount, , ) = IInvestmentAgreement(ia).getDeal(
                    sn.sequenceOfDeal()
                );

            uint16 buyerGroup = sn.groupOfBuyer();

            _mockResults[ia][buyerGroup].buyAmt += amount;

            _addGroup(ia, buyerGroup);

            if (sn.typeOfDeal() > 1) {
                uint16 sellerGroup = _bos.groupNo(
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(sn.sequenceOfDeal())
                        .shareholder()
                );

                _mockResults[ia][sellerGroup].selAmt += amount;

                _addGroup(ia, sellerGroup);
            }
        }

        emit MockDeals(ia);
    }

    function _checkController(address ia, bool basedOnPar) private {
        TopGroup storage top = _topGroups[ia];

        uint16 controller = _bos.controller();
        uint256 amtOfCorp = basedOnPar ? _bos.regCap() : _bos.paidCap();
        amtOfCorp += top.netIncreasedAmt;

        if (isConcernedGroup[ia][controller]) {
            if (top.groupNum == controller) top.isOrgController = true;
        } else {
            uint256 amtOfController = basedOnPar
                ? _bosCal.parOfGroup(controller)
                : _bosCal.paidOfGroup(controller);

            if (top.amount < amtOfController) {
                top.isOrgController = true;
                top.groupNum = controller;
                top.amount = amtOfController;
            }
        }
        top.shareRatio = (top.amount * 10000) / amtOfCorp;
    }

    function _calculateResult(address ia, bool basedOnPar) private {
        uint16[] storage groups = groupsConcerned[ia];
        TopGroup storage top = _topGroups[ia];

        uint256 len = groups.length;

        for (uint256 i = 0; i < len; i++) {
            uint16 groupNum = groups[i];

            Amt storage amt = _mockResults[ia][groupNum];

            if (_bos.isGroup(groupNum))
                amt.orgAmt = basedOnPar
                    ? _bosCal.parOfGroup(groupNum)
                    : _bosCal.paidOfGroup(groupNum);

            require(amt.orgAmt + amt.buyAmt >= amt.selAmt, "amount OVER FLOW");

            amt.rstAmt = amt.orgAmt + amt.buyAmt - amt.selAmt;
            top.netIncreasedAmt += amt.rstAmt;

            if (amt.rstAmt > top.amount) {
                top.amount = amt.rstAmt;
                top.groupNum = groupNum;
            }
        }

        _checkController(ia, basedOnPar);

        emit CalculateResult(
            ia,
            top.groupNum,
            top.amount,
            top.isOrgController,
            top.shareRatio
        );
    }

    function proposeIA(
        address ia,
        uint32 proposeDate,
        uint32 caller
    )
        public
        onlyDirectKeeper
        onlyRegistered(ia)
        currentDate(proposeDate)
        onlyForSubmitted(ia)
    {
        Doc storage doc = _docs[ia];

        require(doc.reviewDeadline <= proposeDate, "still in review period");

        pushToNextState(ia, proposeDate, caller);
    }

    function addAlongDeal(
        address ia,
        bytes32 rule,
        bytes32 shareNumber,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 execDate
    ) external onlyDirectKeeper currentDate(execDate) {
        rejectDoc(ia, execDate, caller);

        uint16 drager = rule.dragerOfLink();
        uint16 follower = _bos.groupNo(shareNumber.shareholder());

        Amt storage fAmt = _mockResults[ia][follower];

        if (!isConcernedGroup[ia][follower]) {
            fAmt.orgAmt = rule.basedOnParOfLink()
                ? _bosCal.parOfGroup(follower)
                : _bosCal.paidOfGroup(follower);
            isConcernedGroup[ia][follower] = true;
            groupsConcerned[ia].push(follower);
        }

        if (rule.basedOnParOfLink()) {
            require(
                fAmt.orgAmt >= (fAmt.selAmt + parValue),
                "parValue over flow"
            );
            fAmt.selAmt += parValue;
        } else {
            require(
                fAmt.orgAmt >= (fAmt.selAmt + paidPar),
                "paidPar over flow"
            );
            fAmt.selAmt += paidPar;
        }

        if (rule.proRataOfLink()) {
            Amt storage dAmt = _mockResults[ia][drager];

            require(
                dAmt.selAmt >=
                    (fAmt.selAmt * dAmt.orgAmt) / fAmt.orgAmt + dAmt.buyAmt,
                "sell amount over flow"
            );
        }

        fAmt.rstAmt = fAmt.orgAmt - fAmt.selAmt;

        emit AddAlongDeal(ia, follower, shareNumber, parValue, paidPar);
    }

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint32 drager,
        bool dragAlong
    ) external onlyKeeper {
        uint16 buyerGroup = _bos.groupNo(sn.buyerOfDeal());
        address term = dragAlong
            ? _getSHA().getTerm(uint8(EnumsRepo.TermTitle.DRAG_ALONG))
            : _getSHA().getTerm(uint8(EnumsRepo.TermTitle.TAG_ALONG));

        bytes32 rule = IAlongs(term).linkRule(_bos.groupNo(drager));

        (, uint256 parValue, uint256 paidPar, , ) = IInvestmentAgreement(ia)
            .getDeal(sn.sequenceOfDeal());

        Amt storage bAmt = _mockResults[ia][buyerGroup];

        if (rule.basedOnParOfLink()) bAmt.buyAmt += parValue;
        else bAmt.buyAmt += paidPar;

        bAmt.rstAmt = bAmt.orgAmt + bAmt.buyAmt - bAmt.selAmt;

        // if (!ISigPage(ia).established()) updateSateOfDoc(ia, 1);

        emit AcceptAlongDeal(ia, drager, sn);
    }

    //##################
    //##    读接口    ##
    //##################

    function topGroup(address ia)
        external
        view
        onlyRegistered(ia)
        onlyForSubmitted(ia)
        returns (
            uint16 groupNum,
            uint256 amount,
            bool isOrgController,
            uint256 netIncreasedAmt,
            uint256 shareRatio
        )
    {
        TopGroup storage top = _topGroups[ia];

        groupNum = top.groupNum;
        amount = top.amount;
        isOrgController = top.isOrgController;
        netIncreasedAmt = top.netIncreasedAmt;
        shareRatio = top.shareRatio;
    }

    function mockResults(address ia, uint16 group)
        external
        view
        onlyRegistered(ia)
        onlyForSubmitted(ia)
        returns (
            uint256 selAmt,
            uint256 buyAmt,
            uint256 orgAmt,
            uint256 rstAmt
        )
    {
        require(isConcernedGroup[ia][group], "NOT concerned group");

        Amt storage amt = _mockResults[ia][group];
        selAmt = amt.selAmt;
        buyAmt = amt.buyAmt;
        orgAmt = amt.orgAmt;
        rstAmt = amt.rstAmt;
    }
}
