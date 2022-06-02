/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "./interfaces/IInvestmentAgreement.sol";

import "../../common/components/interfaces/ISigPage.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/ArrayUtils.sol";

contract AgreementCalculator is BOSSetting {
    using SNParser for bytes32;
    using ArrayUtils for uint16[];
    using ArrayUtils for uint32[];

    function parToSell(address ia, uint32 acct)
        public
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        for (uint256 i = 0; i < len; i++) {
            if (
                dealsList[i].typeOfDeal() > 1 &&
                IInvestmentAgreement(ia)
                    .shareNumberOfDeal(dealsList[i].sequenceOfDeal())
                    .shareholder() ==
                acct
            ) {
                (, uint256 parValue, , , ) = IInvestmentAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += parValue;
            }
        }
    }

    function paidToSell(address ia, uint32 acct)
        public
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        for (uint256 i = 0; i < len; i++)
            if (
                dealsList[i].typeOfDeal() > 1 &&
                IInvestmentAgreement(ia)
                    .shareNumberOfDeal(dealsList[i].sequenceOfDeal())
                    .shareholder() ==
                acct
            ) {
                (, , uint256 paidPar, , ) = IInvestmentAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += paidPar;
            }
    }

    function parToBuy(address ia, uint32 acct)
        internal
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;
        for (uint256 i = 0; i < len; i++)
            if (dealsList[i].buyerOfDeal() == acct) {
                (, uint256 parValue, , , ) = IInvestmentAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += parValue;
            }
    }

    function paidToBuy(address ia, uint32 acct)
        internal
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;
        for (uint256 i = 0; i < len; i++)
            if (dealsList[i].buyerOfDeal() == acct) {
                (, , uint256 paidPar, , ) = IInvestmentAgreement(ia).getDeal(
                    dealsList[i].sequenceOfDeal()
                );
                output += paidPar;
            }
    }

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    function typeOfIA(address ia) external view returns (uint8 output) {
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
