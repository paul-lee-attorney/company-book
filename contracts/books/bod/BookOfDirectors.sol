// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfDirectors.sol";

import "../../common/components/MeetingMinutes.sol";

import "../../common/lib/EnumerableSet.sol";

contract BookOfDirectors is IBookOfDirectors, MeetingMinutes {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Director {
        uint8 title; // 1-Chairman; 2-ViceChairman; 3-Director;
        uint40 acct;
        uint40 appointer;
        uint32 startBN;
        uint32 endBN;
    }

/*
    _dirctors[0] {
        title: maxQtyOfDirectors;
        acct: ViceChair;
        appointer: Chairman;
        startBN: (pending);
        endBN: (pending);
    }
*/

    // userNo => Director
    mapping(uint256 => Director) private _directors;

    EnumerableSet.UintSet private _board;

    //####################
    //##    modifier    ##
    //####################

    modifier directorExist(uint40 acct) {
        require(isDirector(acct), "BOD.directorExist: not a director");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    // ======== Directors ========

    function setMaxQtyOfDirectors(uint8 max) external onlyKeeper {
        _directors[0].title = max;
        emit SetMaxQtyOfDirectors(max);
    }

    function appointDirector(
        uint40 appointer,
        uint40 candidate,
        uint8 title
    ) external onlyManager(1) {
        _addDirector(candidate, appointer, title);
    }

    function _addDirector(
        uint40 candidate,
        uint40 appointer,
        uint8 title
    ) private {
        if (!isDirector(candidate))
            require(
                qtyOfDirectors() < maxQtyOfDirectors(),
                "BOD.addDirector: number of directors overflow"
            );

        uint32 startBN = uint32(block.number);

        uint32 endBN = startBN +
            uint32(_getSHA().tenureOfBoard()) *
            8760 *
            _rc.blocksPerHour();

        _directors[candidate] = Director({
            title: title,
            acct: candidate,
            appointer: appointer,
            startBN: startBN,
            endBN: endBN            
        });

        if (title == uint8(EnumsRepo.TitleOfDirectors.Chairman)) {
            if (_directors[0].appointer == 0) _directors[0].appointer = candidate;
            else revert("BOD.addDirector: Chairman's position is occupied");
        } else if (title == uint8(EnumsRepo.TitleOfDirectors.ViceChairman)) {
            if (_directors[0].acct == 0) _directors[0].acct = candidate;
            else revert("BOD.addDirector: ViceChairman's position is occupied");
        } 
        
        if (_board.add(candidate))
            emit AddDirector(
                title,
                candidate,
                appointer,
                startBN,
                endBN
            );
    }

    function takePosition(uint40 candidate, uint40 nominator)
        external
        onlyManager(1)
    {
        _addDirector(
            candidate,
            nominator,
            uint8(EnumsRepo.TitleOfDirectors.Director)
        );
    }

    function removeDirector(uint40 acct) external onlyManager(1) {
        if (isDirector(acct)) {

            if (_directors[acct].title == uint8(EnumsRepo.TitleOfDirectors.Chairman)) {
                _directors[0].appointer = 0;
            } else if (_directors[acct].title == uint8(EnumsRepo.TitleOfDirectors.ViceChairman)) {
                _directors[0].acct = 0;
            }

            delete _directors[acct];

            _board.remove(acct);

            emit RemoveDirector(acct);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function maxQtyOfDirectors() public view returns (uint8) {
        return _directors[0].title;
    }

    function qtyOfDirectors() public view returns (uint256) {
        return _board.length();
    }

    function appointmentCounter(uint40 appointer)
        external
        view
        returns (uint8 qty)
    {
        uint40[] memory list = _board.valuesToUint40();
        uint len = list.length;

        while (len > 0) {
            if (_directors[len-1].appointer == appointer) qty++;
            len--;
        }
    }

    function isDirector(uint40 acct) public view returns (bool flag) {
        return _board.contains(acct);
    }

    function inTenure(uint40 acct)
        external
        view
        directorExist(acct)
        returns (bool)
    {
        return (_directors[acct].endBN >= block.number && _directors[acct].startBN <= block.number);
    }

    function whoIs(uint8 title) external view returns (uint40) {
        if (title == uint8(EnumsRepo.TitleOfDirectors.Chairman)) return _directors[0].appointer;
        else if (title == uint8(EnumsRepo.TitleOfDirectors.ViceChairman)) return _directors[0].acct;
        else revert("BOD.whoIs: value of title overflow");
    }

    function titleOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint8)
    {
        return _directors[acct].title;
    }

    function appointerOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint40)
    {
        return _directors[acct].appointer;
    }

    function startBNOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint32)
    {
        return _directors[acct].startBN;
    }

    function endBNOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint32)
    {
        return _directors[acct].endBN;
    }

    function directors() external view returns (uint40[] memory) {
        return _board.valuesToUint40();
    }
}
