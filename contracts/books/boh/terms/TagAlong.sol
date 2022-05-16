/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../../boa/interfaces/IAgreement.sol";

import "../../../common/config/BOMSetting.sol";

import "./DragAlong.sol";

import "../../../common/components/interfaces/ISigPage.sol";

contract TagAlong is BOMSetting, DragAlong {
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

    mapping(uint16 => bool) internal _exemptedGroups;

    // ################
    // ##  Term接口  ##
    // ################

    function isExempted(address ia, bytes32 sn)
        public
        onlyKeeper
        returns (bool)
    {
        require(_bom.isPassed(ia), "motion NOT passed");

        if (!isTriggered(ia, sn)) return true;

        (address[] memory consentParties, ) = _bom.getYea(ia);

        uint256 i;

        for (i = 0; i < consentParties.length; i++)
            _exemptedGroups[_bos.groupNo(consentParties[i])] = true;

        address[] memory signers = ISigPage(ia).signers();

        for (i = 0; i < signers.length; i++)
            _exemptedGroups[_bos.groupNo(signers[i])] = true;

        uint16[] memory rightholders = _links[
            _bos.groupNo(
                IAgreement(ia)
                    .shareNumberOfDeal(sn.sequenceOfDeal())
                    .shareholder()
            )
        ].followers;

        for (i = 0; i < rightholders.length; i++)
            if (!_exemptedGroups[rightholders[i]]) return false;

        return true;
    }
}
