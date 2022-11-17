// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfSHA.sol";

import "../../common/components/DocumentsRepo.sol";

contract BookOfSHA is IBookOfSHA, DocumentsRepo {
    mapping(uint256 => address) private _termTemplates;

    // _termTemplates[0]: pointer;

    //##################
    //##    写接口    ##
    //##################

    function setTermTemplate(
        uint8 title,
        address body
    ) external onlyDK {
        require(title > 0, "BOH.setTermTemplate: zero title");
        _termTemplates[title] = body;
        emit SetTermTemplate(title, body);
    }

    function changePointer(address body)
        external
        onlyDK
        onlyRegistered(body)
    {
        if (_termTemplates[0] != address(0)) pushToNextState(_termTemplates[0]);

        pushToNextState(body);

        _termTemplates[0] = body;

        emit ChangePointer(body);
    }

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address) {
        return _termTemplates[0];
    }

    function hasTemplate(uint8 title) public view returns (bool flag) {
        flag = title > 0 && _termTemplates[title] > address(0);
    }

    function getTermTemplate(uint8 title) external view returns (address temp) {
        require(
            hasTemplate(title),
            "BOH.getTermTemplate: template not available"
        );
        temp = _termTemplates[title];
    }
}
