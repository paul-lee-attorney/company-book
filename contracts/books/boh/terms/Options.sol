// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../../../common/ruting/BOSSetting.sol";

// import "../../../common/lib/EnumerableSet.sol";
// import "../../../common/lib/SNFactory.sol";
// import "../../../common/lib/SNParser.sol";
import "../../../common/lib/OptionsRepo.sol";
import "../../../common/access/AccessControl.sol";

import "./IOptions.sol";

contract Options is IOptions, AccessControl {
    using OptionsRepo for OptionsRepo.Repo;

    OptionsRepo.Repo private _options;

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint40[] memory obligors,
        uint64 paid,
        uint64 par
    ) external onlyAttorney returns (bytes32 _sn) {
        _sn = _options.createOption(sn, rightholder, obligors, paid, par);
        emit CreateOpt(_sn, paid, par, rightholder);
    }

    function delOption(bytes32 sn) external onlyAttorney {
        if (_options.removeOption(sn)) {
            emit DelOpt(sn);
        }
    }

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOpts() public view returns (uint40) {
        return _options.counterOfOptions();
    }

    function isOption(bytes32 sn) public view returns (bool) {
        return _options.isOption(sn);
    }

    function qtyOfOpts() external view returns (uint40) {
        return _options.qtyOfOptions();
    }

    function isObligor(bytes32 sn, uint40 acct) external view returns (bool) {
        return _options.isObligor(sn, acct);
    }

    function getOption(bytes32 sn)
        external
        view
        returns (
            uint40 rightholder,
            uint64 paid,
            uint64 par
        )
    {
        (rightholder, , paid, par, ) = _options.getOption(sn);
    }

    function obligorsOfOption(bytes32 sn)
        external
        view
        returns (uint40[] memory)
    {
        return _options.obligorsOfOption(sn);
    }

    function snList() external view returns (bytes32[] memory) {
        return _options.optsList();
    }
}
