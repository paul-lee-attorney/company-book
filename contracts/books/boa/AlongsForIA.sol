/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "./Agreement.sol";

contract AlongsForIA is Agreement {
    //##################
    //##    Event     ##
    //##################

    event CreateAlongDeal(bytes32 indexed sn);

    //##################
    //##    写接口    ##
    //##################

    function createAlongDeal(
        bytes32 shareNumber,
        uint16 ssn,
        uint256 parValue,
        uint256 paidPar,
        uint32 execDate
    ) external onlyKeeper {
        require(_bos.isShare(shareNumber.short()), "shareNumber not exist");

        Deal storage orgDeal = _deals[ssn];

        counterOfDeals++;

        bytes32 sn = _createSN(
            shareNumber.class(),
            4, // 4-TagAlong,
            counterOfDeals,
            orgDeal.sn.buyerOfDeal(),
            orgDeal.sn.groupOfBuyer(),
            shareNumber
        );

        Deal storage addDeal = _deals[counterOfDeals];

        addDeal.sn = sn;
        addDeal.shareNumber = shareNumber;

        addDeal.unitPrice = orgDeal.unitPrice;
        addDeal.closingDate = orgDeal.closingDate;

        addDeal.parValue = parValue;
        addDeal.paidPar = paidPar;

        _dealsList.push(sn);
        isDeal[counterOfDeals] = true;

        // add seller to party and sign the IA
        address seller = shareNumber.shareholder();
        addPartyToDoc(seller);
        addSigOfParty(seller, execDate);

        // remove buyer signature from IA
        removeSigOfParty(orgDeal.sn.buyerOfDeal());
        updateStateOfDoc(1);

        emit CreateAlongDeal(sn);
    }
}
