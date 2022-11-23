// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/Checkpoints.sol";

import "../../books/bos/IBookOfShares.sol";

library OptionsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;
    using SNFactory for bytes;
    using SNParser for bytes32;

    struct Option {
        bytes32 sn;
        bytes32 hashLock;
        uint40 rightholder;
        uint32 closingBN;
        uint8 state; // 0-pending; 1-issued; 2-executed; 3-futureReady; 4-pledgeReady; 5-closed; 6-revoked; 7-expired;
        uint64[3] paid; // 0-optValue; 1-futureValue;
        uint64[2] par;
        EnumerableSet.UintSet obligors;
        Checkpoints.History oracles; //64
        EnumerableSet.Bytes32Set futures;
        EnumerableSet.Bytes32Set pledges;
    }

    // bytes32 snInfo{
    //      uint8 typeOfOpt; 0, 1  //0-call(price); 1-put(price); 2-call(roe); 3-put(roe); 4-call(price) & cnds; 5-put(price) & cnds; 6-call(roe) & cnds; 7-put(roe) & cnds;
    //      uint40 sequenceOfOpt; 1, 5
    //      uint32 triggerBN; 6, 4
    //      uint8 exerciseDays; 10, 1
    //      uint8 closingDays; 11, 1
    //      uint16 class; 12, 2
    //      uint32 rate; 14, 4 // Price, ROE, IRR or other key rate to deduce price.
    //      uint8 logicOperator; 18, 1 // 0-not applicable; 1-and; 2-or; ...
    //      uint8 compareOperator_1; 19, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_1; 20, 4
    //      uint8 compareOperator_2; 24, 1 // 0-not applicable; 1-bigger; 2-smaller; 3-bigger or equal; 4-smaller or equal; ...
    //      uint32 para_2; 25, 4
    // }

    // struct Oracle {
    //     uint64 blocknumber;
    //     uint32 data_1;
    //     uint32 data_2;
    // }

    // struct Future {
    //     uint32 ssn;
    //     uint64 paid;
    //     uint64 par;
    // }

    // _options[0].rightholder: counterOfOpts;

    struct Repo {
        // seq(uint40) => Option
        mapping(bytes32 => Option) options;
        EnumerableSet.Bytes32Set snList;
    }

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(Repo storage repo, bytes32 sn) {
        require(isOption(repo, sn), "OR.optionExist: option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        Repo storage repo,
        bytes32 sn,
        uint40 rightholder,
        uint40[] memory obligors,
        uint64 paid,
        uint64 par
    ) internal returns (bytes32 _sn) {
        require(
            sn.triggerBNOfOpt() > block.number,
            "OR.createOption: trigger block number has passed"
        );
        require(
            sn.exerciseDaysOfOpt() != 0,
            "OR.createOption: ZERO exerciseDays"
        );
        require(
            sn.closingDaysOfOpt() != 0,
            "OR.createOption: ZERO closingDays"
        );
        require(sn.rateOfOpt() != 0, "OR.createOption: rate is ZERO");

        require(rightholder != 0, "OR.createOption: ZERO rightholder");
        require(obligors.length != 0, "OR.createOption: ZERO obligors");

        require(paid != 0, "OR.createOption: ZERO paid");
        require(par >= paid, "OR.createOption: INSUFFICIENT par");

        repo.options[0].rightholder++;

        uint32 seq = uint32(repo.options[0].rightholder);

        _sn = _updateSequence(sn, seq);

        if (repo.snList.add(_sn)) {
            Option storage opt = repo.options[_sn];

            opt.sn = _sn;
            opt.rightholder = rightholder;
            opt.state = 1;
            opt.paid[0] = paid;
            opt.par[0] = par;

            uint256 len = obligors.length;

            while (len != 0) {
                opt.obligors.add(obligors[len - 1]);
                len--;
            }

            return _sn;
        } else return bytes32(0);
    }

    function _updateSequence(bytes32 sn, uint32 seq)
        private
        pure
        returns (bytes32)
    {
        bytes memory _sn = abi.encodePacked(sn);

        _sn = _sn.dateToSN(1, seq);

        return _sn.bytesToBytes32();
    }

    function addObligorIntoOption(
        Repo storage repo,
        bytes32 sn,
        uint40 obligor
    ) internal returns (bool flag) {
        if (
            repo.snList.contains(sn) && repo.options[sn].obligors.add(obligor)
        ) {
            flag = true;
        }
    }

    function removeObligorFromOption(
        Repo storage repo,
        bytes32 sn,
        uint40 obligor
    ) internal returns (bool flag) {
        if (
            repo.snList.contains(sn) &&
            repo.options[sn].obligors.remove(obligor)
        ) {
            flag = true;
        }
    }

    function removeOption(Repo storage repo, bytes32 sn)
        internal
        returns (bool flag)
    {
        if (repo.snList.remove(sn)) {
            delete repo.options[sn];
            flag = true;
        }
    }

    function updateOracle(
        Repo storage repo,
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) internal optionExist(repo, sn) {
        repo.options[sn].oracles.push(d1, d2);
    }

    function execOption(
        Repo storage repo,
        bytes32 sn,
        uint32 blocksPerHour
    ) internal optionExist(repo, sn) {
        Option storage opt = repo.options[sn];

        uint32 triggerBN = sn.triggerBNOfOpt();
        uint32 exerciseDays = uint32(sn.exerciseDaysOfOpt());
        uint32 closingDays = uint32(sn.closingDaysOfOpt());

        require(
            opt.state == 1,
            "OR.createOption: option's state is NOT correct"
        );
        require(
            block.number >= triggerBN,
            "OR.createOption: NOT reached TriggerDate"
        );

        if (exerciseDays != 0)
            require(
                block.number <= triggerBN + exerciseDays * 24 * blocksPerHour,
                "OR.createOption: NOT in exercise period"
            );

        (uint64 d1, uint64 d2) = opt.oracles.latest();

        if (sn.typeOfOpt() > 3)
            require(
                sn.checkConditions(uint32(d1), uint32(d2)),
                "OR.createOption: conditions NOT satisfied"
            );

        opt.closingBN = uint32(block.number) + closingDays * 24 * blocksPerHour;
        opt.state = 2;
    }

    function addFuture(
        Repo storage repo,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        IBookOfShares _bos
    ) internal optionExist(repo, sn) returns (bool flag) {
        Option storage opt = repo.options[sn];

        require(
            block.number <= opt.closingBN,
            "OR.addFuture: MISSED closingDate"
        );
        require(opt.state == 2, "OR.addFuture: option NOT executed");

        uint8 typeOfOpt = sn.typeOfOpt();

        uint32 shortOfShare = shareNumber.ssn();

        require(_bos.isShare(shortOfShare), "OR.addFuture: share NOT exist");

        if (typeOfOpt == 1)
            require(
                opt.rightholder == shareNumber.shareholder(),
                "OR.addFuture: WRONG shareholder"
            );
        else
            require(
                opt.obligors.contains(shareNumber.shareholder()),
                "OR.addFuture: WRONG sharehoder"
            );

        require(opt.paid[0] >= opt.paid[1] + paid, "NOT sufficient paid");
        opt.paid[1] += paid;

        require(opt.par[0] >= opt.par[1] + par, "NOT sufficient par");
        opt.par[1] += par;

        bytes32 ft = _createFt(shareNumber.ssn(), paid, par);

        if (repo.options[sn].futures.add(ft)) {
            if (opt.par[0] == opt.par[1] && opt.paid[0] == opt.paid[1])
                opt.state = 3;
            flag = true;
        }
    }

    function _createFt(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.dateToSN(0, ssn);
        _sn = _sn.intToSN(4, paid, 8);
        _sn = _sn.intToSN(12, par, 8);

        sn = _sn.bytesToBytes32();
    }

    function removeFuture(
        Repo storage repo,
        bytes32 sn,
        bytes32 ft
    ) internal optionExist(repo, sn) returns (bool flag) {
        if (repo.options[sn].futures.remove(ft)) flag = true;
    }

    function requestPledge(
        Repo storage repo,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid
    ) internal optionExist(repo, sn) returns (bool flag) {
        Option storage opt = repo.options[sn];

        require(opt.state < 5, "OR.requestPledge: WRONG state");
        require(opt.state > 1, "OR.requestPledge: WRONG state");

        uint8 typeOfOpt = sn.typeOfOpt();

        if (typeOfOpt % 2 == 1)
            require(
                opt.obligors.contains(shareNumber.shareholder()),
                "OR.requestPledge: WRONG shareholder"
            );
        else
            require(
                opt.rightholder == shareNumber.shareholder(),
                "OR.requestPledge: WRONG sharehoder"
            );

        require(
            opt.paid[0] >= opt.paid[2] + paid,
            "OR.requestPledge: pledge paid OVERFLOW"
        );
        opt.paid[2] += paid;

        bytes32 pld = _createFt(shareNumber.ssn(), paid, paid);

        if (opt.pledges.add(pld)) {
            if (opt.paid[0] == opt.paid[2]) opt.state = 4;
            flag = true;
        }
    }

    function lockOption(
        Repo storage repo,
        bytes32 sn,
        bytes32 hashLock
    ) internal optionExist(repo, sn) {
        Option storage opt = repo.options[sn];
        require(opt.state > 1, "OR.lockOption: WRONG state");
        opt.hashLock = hashLock;
    }

    function closeOption(
        Repo storage repo,
        bytes32 sn,
        string memory hashKey
    ) internal optionExist(repo, sn) {
        Option storage opt = repo.options[sn];

        require(opt.state > 1, "OR.closeOption: WRONG state");
        require(opt.state < 5, "OR.closeOption: WRONG state");
        require(
            block.number <= opt.closingBN,
            "OR.closeOption: MISSED closingDate"
        );
        require(
            opt.hashLock == keccak256(bytes(hashKey)),
            "OR.closeOption: WRONG key"
        );

        opt.state = 5;
    }

    function revokeOption(Repo storage repo, bytes32 sn)
        internal
        optionExist(repo, sn)
    {
        Option storage opt = repo.options[sn];

        require(opt.state < 5, "WRONG state");
        require(block.number > opt.closingBN, "closing period NOT expired");

        opt.state = 6;
    }

    // ################
    // ##  查询接口   ##
    // ###############

    function counterOfOptions(Repo storage repo)
        internal
        view
        returns (uint40)
    {
        return repo.options[0].rightholder;
    }

    function qtyOfOptions(Repo storage repo) internal view returns (uint40) {
        return uint40(repo.snList.length());
    }

    function isOption(Repo storage repo, bytes32 sn)
        internal
        view
        returns (bool)
    {
        return repo.snList.contains(sn);
    }

    function getOption(Repo storage repo, bytes32 sn)
        internal
        view
        returns (
            uint40 rightholder,
            uint32 closingBN,
            uint64 paid,
            uint64 par,
            bytes32 hashLock
        )
    {
        Option storage opt = repo.options[sn];
        rightholder = opt.rightholder;
        closingBN = opt.closingBN;
        paid = opt.paid[0];
        par = opt.par[0];
        hashLock = opt.hashLock;
    }

    function isObligor(
        Repo storage repo,
        bytes32 sn,
        uint40 acct
    ) internal view returns (bool) {
        return repo.options[sn].obligors.contains(acct);
    }

    function obligorsOfOption(Repo storage repo, bytes32 sn)
        internal
        view
        returns (uint40[] memory)
    {
        return repo.options[sn].obligors.valuesToUint40();
    }

    function stateOfOption(Repo storage repo, bytes32 sn)
        internal
        view
        returns (uint8)
    {
        return repo.options[sn].state;
    }

    function futures(Repo storage repo, bytes32 sn)
        internal
        view
        returns (bytes32[] memory)
    {
        return repo.options[sn].futures.values();
    }

    function pledges(Repo storage repo, bytes32 sn)
        internal
        view
        returns (bytes32[] memory)
    {
        return repo.options[sn].pledges.values();
    }

    function oracle(
        Repo storage repo,
        bytes32 sn,
        uint64 blockNumber
    ) internal view returns (uint32, uint32) {
        (uint64 d1, uint64 d2) = repo.options[sn].oracles.getAtBlock(
            blockNumber
        );
        return (uint32(d1), uint32(d2));
    }

    function optsList(Repo storage repo)
        internal
        view
        returns (bytes32[] memory)
    {
        return repo.snList.values();
    }
}
