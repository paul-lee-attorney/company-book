// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfSHA.sol";

import "../../common/components/DocumentsRepo.sol";

contract BookOfSHA is IBookOfSHA, DocumentsRepo {
    mapping(uint256 => address) private _templates;

    // _templates[0]: pointer;

    //##################
    //##    写接口    ##
    //##################

    function addTermTemplate(
        uint8 title,
        address add,
        uint40 caller
    ) external onlyManager(1) {
        require(title > 0, "BOH.addTermTemplate: zero title");
        require(caller == getManager(0), "caller is not Owner");
        _templates[title] = add;
        emit AddTemplate(title, add);
    }

    function changePointer(address body)
        external
        onlyManager(1)
        onlyRegistered(body)
    {
        if (_templates[0] != address(0)) pushToNextState(_templates[0]);

        pushToNextState(body);

        _templates[0] = body;

        emit ChangePointer(body);
    }

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address) {
        return _templates[0];
    }

    function hasTemplate(uint8 title) public view returns (bool flag) {
        flag = title > 0 && _templates[title] > address(0);
    }

    function getTermTemplate(uint8 title) external view returns (address temp) {
        require(
            hasTemplate(title),
            "BOH.getTermTemplate: template not available"
        );
        temp = _templates[title];
    }
}
