/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./interfaces/IAgreement.sol";

import "../../common/components/interfaces/ISigPage.sol";
import "../../common/config/BOSSetting.sol";
import "../../common/lib/serialNumber/DealSNParser.sol";
import "../../common/lib/serialNumber/ShareSNParser.sol";
import "../../common/lib/ArrayUtils.sol";

contract AgreementCalculator is BOSSetting {
    using DealSNParser for bytes32;
    using ShareSNParser for bytes32;
    using ArrayUtils for uint16[];
    using ArrayUtils for address[];

    function parToSell(address ia, address acct)
        public
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        for (uint256 i = 0; i < len; i++) {
            if (
                dealsList[i].typeOfDeal() > 1 &&
                IAgreement(ia)
                    .shareNumberOfDeal(dealsList[i].sequenceOfDeal())
                    .shareholder() ==
                acct
            ) {
                (, , uint256 parValue, , , , ) = IAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += parValue;
            }
        }
    }

    function paidToSell(address ia, address acct)
        public
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        for (uint256 i = 0; i < len; i++)
            if (
                dealsList[i].typeOfDeal() > 1 &&
                IAgreement(ia)
                    .shareNumberOfDeal(dealsList[i].sequenceOfDeal())
                    .shareholder() ==
                acct
            ) {
                (, , , uint256 paidPar, , , ) = IAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += paidPar;
            }
    }

    function parToBuy(address ia, address acct)
        internal
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();
        uint256 len = dealsList.length;
        for (uint256 i = 0; i < len; i++)
            if (dealsList[i].buyerOfDeal() == acct) {
                (, , uint256 parValue, , , , ) = IAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += parValue;
            }
    }

    function paidToBuy(address ia, address acct)
        internal
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();
        uint256 len = dealsList.length;
        for (uint256 i = 0; i < len; i++)
            if (dealsList[i].buyerOfDeal() == acct) {
                (, , , uint256 paidPar, , , ) = IAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += paidPar;
            }
    }

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    function typeOfIA(address ia) external view returns (uint8 output) {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();
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

    function otherMembers(address ia) external view returns (address[]) {
        address[] memory signers = ISigPage(ia).signers();
        address[] memory members = _bos.membersList();

        return members.minus(signers);
    }
}
