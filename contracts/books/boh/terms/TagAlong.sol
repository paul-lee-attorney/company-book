/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/interfaces/IInvestmentAgreement.sol";

import "../../../common/ruting/BOMSetting.sol";

import "../../../common/lib/ObjGroup.sol";
import "../../../common/lib/ArrayUtils.sol";

import "./DragAlong.sol";

import "../../../common/components/interfaces/ISigPage.sol";

contract TagAlong is BOMSetting, DragAlong {
    using ObjGroup for ObjGroup.SeqList;
    using ArrayUtils for uint40[];

    // struct linkRule {
    //     uint16 drager;
    //     // 0-no condition; 1- biggest && shareRatio > threshold;
    //     uint8 triggerType;
    //     bool basedOnPar;
    //     // threshold to define material control party
    //     uint32 threshold;
    //     // false - free amount; true - pro rata (transfered parValue : original parValue)
    //     bool proRata;
    //     uint32 unitPrice;
    //     uint32 ROE;
    // }

    ObjGroup.SeqList private _supportGroups;

    // ################
    // ##  Term接口  ##
    // ################

    function isExempted(address ia, bytes32 sn) public onlyUser returns (bool) {
        require(_bom.isPassed(ia), "motion NOT passed");

        if (!isTriggered(ia, sn)) return true;

        (uint40[] memory consentParties, ) = _bom.getYea(ia);

        uint40[] memory signers = ISigPage(ia).parties();

        uint40[] memory supporters = consentParties.combine(signers);

        uint256 len = supporters.length;

        _supportGroups.emptyItems();

        while (len > 0) {
            _supportGroups.addItem(_bos.groupNo(supporters[len - 1]));
            len--;
        }

        uint16[] memory rightholders = _links[
            _bos.groupNo(
                IInvestmentAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder()
            )
        ].followerGroups.items;

        len = rightholders.length;

        while (len > 0) {
            if (!_supportGroups.isItem[rightholders[len - 1]]) return false;
            len--;
        }

        return true;
    }
}
