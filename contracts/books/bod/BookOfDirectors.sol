/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

// pragma experimental ABIEncoderV2;

// import "../boa//IInvestmentAgreement.sol";

// import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/SHASetting.sol";
// import "../../common/ruting/BOSSetting.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumsRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/access/AccessControl.sol";

import "./IBookOfDirectors.sol";

contract BookOfDirectors is IBookOfDirectors, SHASetting {
    using SNFactory for bytes;
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Director {
        uint8 title; // 1-Chairman; 2-ViceChairman; 3-Director;
        uint40 appointer;
        uint32 inaugurationDate;
        uint32 expirationDate;
    }

    // userNo => Director
    mapping(uint40 => Director) private _directors;

    // appointer => numOfDirector nominated;
    mapping(uint40 => uint8) private _appointmentCounter;

    // title => userNo
    mapping(uint8 => uint40) private _whoIs;

    EnumerableSet.UintSet private _snList;

    uint8 private _maxNumOfDirectors;

    //####################
    //##    modifier    ##
    //####################

    modifier directorExist(uint40 acct) {
        require(_snList.contains(acct), "not a director");
        require(
            _directors[acct].expirationDate >= now + 15 minutes,
            "tenure expired"
        );
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setMaxNumOfDirectors(uint8 num) external onlyKeeper {
        _maxNumOfDirectors = num;
        emit SetMaxNumOfDirectors(num);
    }

    function appointDirector(
        uint40 appointer,
        uint40 candidate,
        uint8 title
    ) external onlyDirectKeeper {
        _addDirector(candidate, appointer, title);
    }

    function _addDirector(
        uint40 candidate,
        uint40 appointer,
        uint8 title
    ) private {
        if (!_snList.contains(candidate))
            require(
                _snList.length() < _maxNumOfDirectors,
                "number of directors overflow"
            );

        if (appointer > 0) _appointmentCounter[appointer]++;

        uint32 inaugurationDate = uint32(block.number);

        uint32 expirationDate = inaugurationDate +
            uint32(_getSHA().tenureOfBoard()) *
            31536000;

        Director storage director = _directors[candidate];

        director.title = title;
        director.appointer = appointer;
        director.inaugurationDate = inaugurationDate;
        director.expirationDate = expirationDate;

        if (title != uint8(EnumsRepo.TitleOfDirectors.Director))
            _whoIs[title] = candidate;

        _snList.add(candidate);

        emit AddDirector(
            candidate,
            title,
            appointer,
            inaugurationDate,
            expirationDate
        );
    }

    function takePosition(uint40 candidate) external onlyDirectKeeper {
        _addDirector(candidate, 0, uint8(EnumsRepo.TitleOfDirectors.Director));
    }

    function removeDirector(uint40 acct) external onlyDirectKeeper {
        if (_snList.remove(acct)) {
            uint8 title = _directors[acct].title;
            if (uint40(_whoIs[title]) == acct) delete _whoIs[title];

            uint40 appointer = _directors[acct].appointer;
            if (appointer > 0) _appointmentCounter[appointer]--;

            delete _directors[acct];

            emit RemoveDirector(acct, title);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function maxNumOfDirectors() external view onlyUser returns (uint8) {
        return _maxNumOfDirectors;
    }

    function appointmentCounter(uint40 appointer)
        external
        view
        onlyUser
        returns (uint8)
    {
        return _appointmentCounter[appointer];
    }

    function isDirector(uint40 acct) external view onlyUser returns (bool) {
        return _snList.contains(acct);
    }

    function inTenure(uint40 acct)
        external
        view
        directorExist(acct)
        onlyUser
        returns (bool)
    {
        return (uint256(_directors[acct].expirationDate) >= now + 15 minutes);
    }

    function whoIs(uint8 title) external view onlyUser returns (uint40) {
        require(
            title != uint8(EnumsRepo.TitleOfDirectors.Director),
            "director is not a special title"
        );

        uint40 userNo = _whoIs[title];

        if (_directors[userNo].title != title) userNo = 0;

        return userNo;
    }

    function titleOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint8)
    {
        return _directors[acct].title;
    }

    function appointerOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint40)
    {
        return _directors[acct].appointer;
    }

    function inaugurationDateOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint32)
    {
        return _directors[acct].inaugurationDate;
    }

    function expirationDateOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint32)
    {
        return _directors[acct].expirationDate;
    }

    function qtyOfDirectors() external view onlyUser returns (uint256) {
        return _snList.length();
    }

    function directors() external view onlyUser returns (uint40[]) {
        return _snList.valuesToUint40();
    }
}
