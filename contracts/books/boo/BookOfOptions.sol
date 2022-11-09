// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfOptions.sol";

import "../boh/terms/IOptions.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/OptionsRepo.sol";

import "../../common/ruting/BOSSetting.sol";

contract BookOfOptions is IBookOfOptions, BOSSetting {
    using OptionsRepo for OptionsRepo.Repo;
    using SNParser for bytes32;

    enum TypeOfOption {
        Call_Price,
        Put_Price,
        Call_ROE,
        Put_ROE,
        Call_PriceAndConditions,
        Put_PriceAndConditions,
        Call_ROEAndConditions,
        Put_ROEAndConditions
    }

    enum StateOfOption {
        Pending,
        Issued,
        Executed,
        Futured,
        Pledged,
        Closed,
        Revoked,
        Expired
    }

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
    ) external onlyKeeper returns (bytes32 _sn) {
        _sn = _options.createOption(sn, rightholder, obligors, paid, par);
        emit CreateOpt(_sn, rightholder, paid, par);
    }

    function registerOption(address opts) external onlyKeeper {
        bytes32[] memory list = IOptions(opts).snList();
        uint256 len = list.length;

        while (len > 0) {
            bytes32 sn = list[len - 1];

            len--;

            if (!IOptions(opts).isOption(sn)) continue;

            (uint40 rightholder, uint64 paid, uint64 par) = IOptions(opts)
                .getOption(sn);

            sn = _options.createOption(
                sn,
                rightholder,
                IOptions(opts).obligorsOfOption(sn),
                paid,
                par
            );

            emit RegisterOpt(sn, paid, par);
        }
    }

    function addObligorIntoOption(bytes32 sn, uint40 obligor) external {
        if (_options.addObligorIntoOption(sn, obligor))
            emit AddObligorIntoOpt(sn, obligor);
    }

    function removeObligorFromOption(bytes32 sn, uint40 obligor) external {
        if (_options.removeObligorFromOption(sn, obligor))
            emit RemoveObligorFromOpt(sn, obligor);
    }

    function updateOracle(
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) external onlyKeeper {
        _options.updateOracle(sn, d1, d2);
        emit UpdateOracle(sn, d1, d2);
    }

    function execOption(bytes32 sn) external onlyKeeper {
        _options.execOption(sn, _rc.blocksPerHour());
        emit ExecOpt(sn);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par
    ) external onlyKeeper {
        if (_options.addFuture(sn, shareNumber, paid, par, _bos)) {
            emit AddFuture(sn, shareNumber, paid, par);
        }
    }

    function removeFuture(bytes32 sn, bytes32 ft) external onlyKeeper {
        if (_options.removeFuture(sn, ft)) {
            emit RemoveFuture(sn, ft);
        }
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid
    ) external onlyKeeper {
        if (_options.requestPledge(sn, shareNumber, paid))
            emit AddPledge(sn, shareNumber, paid);
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external onlyKeeper {
        _options.lockOption(sn, hashLock);
        emit LockOpt(sn, hashLock);
    }

    function closeOption(bytes32 sn, string memory hashKey)
        external
        onlyKeeper
    {
        _options.closeOption(sn, hashKey);
        emit CloseOpt(sn, hashKey);
    }

    function revokeOption(bytes32 sn) external onlyKeeper {
        _options.revokeOption(sn);
        emit RevokeOpt(sn);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint40) {
        return _options.counterOfOptions();
    }

    function isOption(bytes32 sn) public view returns (bool) {
        return _options.isOption(sn);
    }

    function getOption(bytes32 sn)
        external
        view
        returns (
            uint40 rightholder,
            uint32 closingBN,
            uint64 paid,
            uint64 par,
            bytes32 hashLock
        )
    {
        return _options.getOption(sn);
    }

    function isObligor(bytes32 sn, uint40 acct) external view returns (bool) {
        return _options.isObligor(sn, acct);
    }

    function obligorsOfOption(bytes32 sn)
        external
        view
        returns (uint40[] memory)
    {
        return _options.obligorsOfOption(sn);
    }

    function stateOfOption(bytes32 sn) external view returns (uint8) {
        return _options.stateOfOption(sn);
    }

    function futures(bytes32 sn) external view returns (bytes32[] memory) {
        return _options.futures(sn);
    }

    function pledges(bytes32 sn) external view returns (bytes32[] memory) {
        return _options.pledges(sn);
    }

    function oracle(bytes32 sn, uint64 blockNumber)
        external
        view
        returns (uint32, uint32)
    {
        return _options.oracle(sn, blockNumber);
    }

    function snList() external view returns (bytes32[] memory) {
        return _options.optsList();
    }
}
