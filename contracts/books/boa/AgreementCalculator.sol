/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../../common/interfaces/IAgreement.sol";
import "../../common/config/BOSSetting.sol";
import "../../common/lib/serialNumber/DealSNParser.sol";

contract AgreementCalculator is BOSSetting {
    using DealSNParser for bytes32;

    function parToSell(address ia, address acct)
        internal
        view
        returns (uint256 output)
    {
        bytes32[] memory dealsList = IAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        for (uint256 i = 0; i < len; i++)
            if (
                dealsList[i].typeOfDeal() > 1 &&
                dealsList[i].sellerOfDeal(_bos.snList()) == acct
            ) {
                (, uint256 parValue, , , , ) = IAgreement(ia).getDeal(
                    dealsList[i].shortOfDeal()
                );
                output += parValue;
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
            if (dealsList[i].typeOfDeal() > 1 && dealsList[i].buyerOfDeal() == acct) {
                (, uint256 parValue, , , , ) = IAgreement(ia).getDeal(
                    dealsList[i].shortOfDeal()
                );
                output += parValue;
            }
    }

    // 1-CI 2-ST(to 3rd) 3-ST(internal) 4-(1&3) 5-(2&3) 6-(1&2&3) 7-(1&2)
    function typeOfIA(address ia) internal view returns (uint8 output) {
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
}
