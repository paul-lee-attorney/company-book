// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SNParser.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";
import "../../common/access/AccessControl.sol";

import "./IBOSCalculator.sol";

contract BOSCalculator is IBOSCalculator, BOSSetting, ROMSetting {
    using SNParser for bytes32;

    //##################
    //##   查询接口   ##
    //##################

    function membersOfClass(uint16 class)
        external
        view
        returns (uint40[] memory)
    {
        require(class < _bos.counterOfClasses(), "class over flow");

        bytes32[] memory list = _rom.sharesList();

        uint256 len = _rom.qtyOfMembers();
        uint40[] memory members = new uint40[](len);

        uint256 numOfMembers;
        len = list.length;

        while (len > 0) {
            if (list[len - 1].class() == class) {
                uint256 lenOfM = numOfMembers;
                while (lenOfM > 0) {
                    if (members[lenOfM - 1] == list[len - 1].shareholder())
                        break;
                    lenOfM--;
                }
                if (lenOfM == 0) {
                    numOfMembers++;
                    members[numOfMembers - 1] = list[len - 1].shareholder();
                }
            }
            len--;
        }

        uint40[] memory output = new uint40[](numOfMembers);

        assembly {
            output := members
        }

        return output;
    }

    function sharesOfClass(uint16 class)
        external
        view
        returns (bytes32[] memory)
    {
        require(class < _bos.counterOfClasses(), "class over flow");

        bytes32[] memory list = _rom.sharesList();

        uint256 len = list.length;
        bytes32[] memory shares = new bytes32[](len);

        uint256 numOfShares;

        while (len > 0) {
            if (list[len - 1].class() == class) {
                numOfShares++;
                shares[numOfShares - 1] = list[len - 1];
            }
            len--;
        }

        bytes32[] memory output = new bytes32[](numOfShares);

        assembly {
            output := shares
        }

        return output;
    }
}
