/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./InvestmentAgreementWithFirstRefusal.sol";

// import "../../common/lib/UserGroup.sol";
// import "../../common/lib/SignerGroup.sol";

contract AgreementWithAlongs is InvestmentAgreementWithFirstRefusal {
    // using UserGroup for UserGroup.Group;
    // using SignerGroup for SignerGroup.Group;

    //##################
    //##    Event     ##
    //##################

    event CreateTagAlongDeal(bytes32 indexed sn);

    event AcceptAlongDeal(bytes32 indexed sn, uint32 caller);

    //##################
    //##    写接口    ##
    //##################

    function createTagAlongDeal(
        bytes32 shareNumber,
        uint16 ssn,
        uint256 parValue,
        uint256 paidPar,
        uint32 caller,
        uint32 execDate,
        bytes32 sigHash
    ) external onlyDirectKeeper {
        require(_bos.isShare(shareNumber.short()), "shareNumber not exist");

        Deal storage orgDeal = _deals[ssn];

        counterOfDeals++;

        bytes32 sn = _createSN(
            shareNumber.class(),
            4, // 4-TagAlongDeal,
            counterOfDeals,
            orgDeal.sn.buyerOfDeal(),
            orgDeal.sn.groupOfBuyer(),
            shareNumber,
            orgDeal.sn.sequenceOfDeal()
        );

        Deal storage addDeal = _deals[counterOfDeals];

        addDeal.sn = sn;
        addDeal.shareNumber = shareNumber;

        addDeal.unitPrice = orgDeal.unitPrice;
        addDeal.closingDate = orgDeal.closingDate;

        addDeal.parValue = parValue;
        addDeal.paidPar = paidPar;

        // set original Deal state to suspend;
        orgDeal.states.currentState += 4;

        _dealsList.push(sn);
        isDeal[counterOfDeals] = true;

        // add caller to party and sign the IA
        addPartyToDoc(caller);
        _addSigOfParty(caller, execDate, sigHash);

        // add buyer to party again;
        addPartyToDoc(sn.buyerOfDeal());

        // turn off flag of established
        established = false;

        emit CreateTagAlongDeal(sn);
    }

    function acceptTagAlongDeal(
        bytes32 sn,
        uint32 caller,
        uint32 sigDate,
        bytes32 sigHash
    ) external onlyDirectKeeper {
        // recover state of original deal to normal
        if (_deals[sn.preSSNOfDeal()].states.currentState >= 4)
            _deals[sn.preSSNOfDeal()].states.currentState -= 4;

        _addSigOfParty(caller, sigDate, sigHash);

        emit AcceptAlongDeal(sn, caller);
    }
}
