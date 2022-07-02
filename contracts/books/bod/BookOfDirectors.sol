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
    // using EnumerableSet for EnumerableSet.BallotsBox;

    struct Director {
        uint8 title; // 1-Chairman; 2-ViceChairman; 3-Director;
        uint40 nominator;
        uint32 inaugurationDate;
        uint32 expirationDate;
    }

    // userNo => Director
    mapping(uint256 => Director) private _directors;

    // title => userNo
    mapping(uint256 => uint256) private _whoIs;

    EnumerableSet.UintSet private _snList;

    uint256 private _maxNumOfDirectors;

    //####################
    //##    modifier    ##
    //####################

    modifier directorExist(uint256 acct) {
        require(_snList.contains(acct), "not a director");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setNumOfDirectors(uint256 num) external onlyDirectKeeper {
        _maxNumOfDirectors = num;
        emit SetNumOfDirectors(num);
    }

    function addDirector(
        uint40 nominator,
        uint40 acct,
        uint8 title
    ) external onlyDirectKeeper {
        if (!_snList.contains(acct))
            require(
                _snList.length() < _maxNumOfDirectors,
                "number of directors overflow"
            );

        uint32 inaugurationDate = uint32(block.number);

        uint32 expirationDate = inaugurationDate +
            _getSHA().tenureOfBoard() *
            31536000;

        Director storage director = _directors[acct];

        director.title = title;
        director.nominator = nominator;
        director.inaugurationDate = inaugurationDate;
        director.expirationDate = expirationDate;

        if (title != uint8(EnumsRepo.TitleOfDirectors.Director))
            _whoIs[title] = acct;

        _snList.add(acct);

        emit AddDirector(
            acct,
            title,
            nominator,
            inaugurationDate,
            expirationDate
        );
    }

    function removeDirector(uint40 acct) external onlyDirectKeeper {
        if (_snList.remove(acct)) {
            uint8 title = _directors[acct].title;
            if (uint40(_whoIs[title]) == acct) delete _whoIs[title];

            delete _directors[acct];

            emit RemoveDirector(acct, title);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function maxNumOfDirectors() external view onlyUser returns (uint256) {
        return _maxNumOfDirectors;
    }

    function isDirector(uint40 acct) external view onlyUser returns (bool) {
        return
            _snList.contains(acct) &&
            (uint256(_directors[acct].expirationDate) >= now + 15 minutes);
    }

    function whoIs(uint8 title) external view onlyUser returns (uint40) {
        require(
            title != uint8(EnumsRepo.TitleOfDirectors.Director),
            "director is not a special title"
        );

        uint256 userNo = _whoIs[title];

        if (_directors[userNo].title != title) userNo = 0;

        return uint40(userNo);
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

    function nominatorOfDirector(uint40 acct)
        external
        view
        onlyUser
        directorExist(acct)
        returns (uint40)
    {
        return _directors[acct].nominator;
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
