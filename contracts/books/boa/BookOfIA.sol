/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./interfaces/IInvestmentAgreement.sol";

import "../boh/terms/interfaces/IAlongs.sol";

import "../../common/components/interfaces/ISigPage.sol";
import "../../common/components/BookOfDocuments.sol";

import "../../common/ruting/SHASetting.sol";

import "../../common/lib/ArrayUtils.sol";
import "../../common/lib/ObjGroup.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";

contract BookOfIA is BookOfDocuments, SHASetting {
    using SNParser for bytes32;
    using ObjGroup for ObjGroup.SeqList;
    using ArrayUtils for uint32[];

    struct Amt {
        uint256 selAmt;
        uint256 buyAmt;
        uint256 orgAmt;
        uint256 rstAmt;
    }

    // IA address => group => Amt
    mapping(address => mapping(uint16 => Amt)) private _mockResults;

    // IA address => SeqList
    mapping(address => ObjGroup.SeqList) private _groupsConcerned;

    // IA address => deal seq => bool
    mapping(address => mapping(uint16 => bool)) private _isMocked;

    struct TopGroup {
        uint16 groupNum;
        uint256 amount;
        bool isOrgController;
        uint256 netIncreasedAmt;
        uint256 shareRatio;
    }

    // IA address => topGroup
    mapping(address => TopGroup) private _topGroups;

    //##############
    //##  Event   ##
    //##############

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
    //##  Write I/O  ##
    //#################

    function submitIA(
        address ia,
        uint32 submitter,
        uint32 submitDate,
        bytes32 docHash
    ) external onlyDirectKeeper {
        submitDoc(ia, submitter, submitDate, docHash);
        bool basedOnPar = _getSHA().votingRules(typeOfIA(ia)).basedOnParOfVR();
        _mockDeals(ia, basedOnPar);
        _calculateResult(ia, basedOnPar);
    }

    function _mockDeals(address ia, bool basedOnPar) private {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        for (uint256 i = 0; i < len; i++) {
            bytes32 sn = dealsList[i];

            uint256 amount;
            uint8 state;

            if (basedOnPar)
                (, amount, , state, ) = IInvestmentAgreement(ia).getDeal(
                    sn.sequenceOfDeal()
                );
            else
                (, , amount, state, ) = IInvestmentAgreement(ia).getDeal(
                    sn.sequenceOfDeal()
                );

            uint16 buyerGroup = sn.groupOfBuyer();

            if (_isMocked[ia][sn.sequenceOfDeal()]) {
                if (state != uint8(EnumsRepo.StateOfDeal.Terminated)) continue;
                else _mockResults[ia][buyerGroup].buyAmt -= amount;
            } else {
                _mockResults[ia][buyerGroup].buyAmt += amount;
                _groupsConcerned[ia].addItem(buyerGroup);
            }

            if (sn.typeOfDeal() > 1) {
                uint16 sellerGroup = _bos.groupNo(
                    IInvestmentAgreement(ia)
                        .shareNumberOfDeal(sn.sequenceOfDeal())
                        .shareholder()
                );

                if (
                    _isMocked[ia][sn.sequenceOfDeal()] &&
                    state == uint8(EnumsRepo.StateOfDeal.Terminated)
                ) _mockResults[ia][sellerGroup].selAmt -= amount;
                else {
                    _mockResults[ia][sellerGroup].selAmt += amount;
                    _groupsConcerned[ia].addItem(sellerGroup);
                }
            }

            _isMocked[ia][sn.sequenceOfDeal()] = true;
        }

        emit MockDeals(ia);
    }

    function _calculateResult(address ia, bool basedOnPar) private {
        uint16[] storage groups = _groupsConcerned[ia].items;
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

    function _checkController(address ia, bool basedOnPar) private {
        TopGroup storage top = _topGroups[ia];

        uint16 controller = _bos.controller();
        uint256 amtOfCorp = basedOnPar ? _bos.regCap() : _bos.paidCap();
        amtOfCorp += top.netIncreasedAmt;

        if (_groupsConcerned[ia].isItem[controller]) {
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

        if (_groupsConcerned[ia].addItem(follower))
            fAmt.orgAmt = rule.basedOnParOfLink()
                ? _bosCal.parOfGroup(follower)
                : _bosCal.paidOfGroup(follower);

        // if (!_isConcernedGroup[ia][follower]) {
        //     fAmt.orgAmt = rule.basedOnParOfLink()
        //         ? _bosCal.parOfGroup(follower)
        //         : _bosCal.paidOfGroup(follower);
        //     _isConcernedGroup[ia][follower] = true;
        //     _groupsConcerned[ia].push(follower);
        // }

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

        _isMocked[ia][sn.sequenceOfDeal()] = true;

        emit AcceptAlongDeal(ia, drager, sn);
    }

    //##################
    //##    读接口    ##
    //##################

    function groupsConcerned(address ia)
        external
        view
        onlyUser
        returns (uint16[])
    {
        return _groupsConcerned[ia].items;
    }

    function isConcernedGroup(address ia, uint16 group)
        external
        view
        onlyUser
        returns (bool)
    {
        return _groupsConcerned[ia].isItem[group];
    }

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
        onlyUser
        onlyForSubmitted(ia)
        returns (
            uint256 selAmt,
            uint256 buyAmt,
            uint256 orgAmt,
            uint256 rstAmt
        )
    {
        require(_groupsConcerned[ia].isItem[group], "NOT concerned group");

        Amt storage amt = _mockResults[ia][group];
        selAmt = amt.selAmt;
        buyAmt = amt.buyAmt;
        orgAmt = amt.orgAmt;
        rstAmt = amt.rstAmt;
    }

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    function typeOfIA(address ia) public view returns (uint8 output) {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;
        uint8[3] memory signal;

        for (uint256 i = 0; i < len; i++) {
            uint8 typeOfDeal = dealsList[i].typeOfDeal();
            signal[typeOfDeal - 1] = typeOfDeal;
        }
        // 协议类别计算
        uint8 sumOfSignal = signal[0] + signal[1] + signal[2];
        output = sumOfSignal == 3 ? signal[2] == 0 ? 7 : 3 : sumOfSignal;
    }

    function otherMembers(address ia) external view returns (uint32[]) {
        uint32[] memory signers = ISigPage(ia).parties();
        uint32[] memory members = _bos.membersList();

        return members.minus(signers);
    }
}
