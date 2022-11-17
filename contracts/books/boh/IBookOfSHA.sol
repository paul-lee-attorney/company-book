// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IDocumentsRepo.sol";

interface IBookOfSHA is IDocumentsRepo {
    //##############
    //##  Event   ##
    //##############

    event AddTemplate(uint8 indexed title, address add);

    event ChangePointer(address indexed pointer);

    //##################
    //##    写接口    ##
    //##################

    function addTermTemplate(
        uint8 title,
        address add,
        uint40 caller
    ) external;

    function changePointer(address body) external;

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address);

    function hasTemplate(uint8 title) external view returns(bool flag);

    function getTermTemplate(uint8 title) external view returns(address temp);

}
