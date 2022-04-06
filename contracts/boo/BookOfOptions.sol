/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../config/BOSSetting.sol";
// import "../config/BOMSetting.sol";
import "../config/BOASetting.sol";
import "../config/AdminSetting.sol";

import "../lib/ArrayUtils.sol";
import "../lib/serialNumber/SNFactory.sol";
import "../lib/ShareSNParser.sol";

// import "../interfaces/IAgreement.sol";
// import "../interfaces/ISigPage.sol";

contract BookOfOptions is BOSSetting {
    // using ArrayUtils for address[];
    using ArrayUtils for bytes32[];
    using SNFactory for bytes;
    using ShareSNParser for bytes32;

    struct Option {
        address rightholder;
        uint256 closingDate;
        uint256 parValue;
        bytes32 hashLock;
        uint8 state; // 0-pending; 1-issued; 2-executed; 3-futureReady; 4-closed; 5-expired;
    }

    // bytes32 snOfOpt{
        // uint32 triggerDate;
        // uint16 counterOfOptions;
        // uint8 exerciseDays;
        // uint8 closingDays;
        // uint8 typeOfOpt; //0-call; 1-put
        // address obligor;
        // uint24 price;
    // }

    // sn => Option
    mapping(bytes32 => Option) private _options;

    // bytes32 future {
    //     uint48 shortShareNumber; 0-5
    //     uint208 parValue; 6-31
    // }

    // sn => futures
    mapping(bytes32 => bytes32[]) public futures;

    mapping(bytes32 => bool) public isOption;

    bytes32[] public snList;

    uint16 public counterOfOpts;

    // ################
    // ##   Event    ##
    // ################

    event SetOpt(bytes32 indexed sn, address rightholder, uint256 parValue);

    event DelOpt(bytes32 indexed sn);

    event CloseOpt(bytes32 indexed sn, bytes32 hashKey);

    event SetOptState(bytes32 indexed sn, uint8 state);

    event ExecOpt(bytes32 indexed sn, uint256 exerciseDate, bytes32 hashLock);

    event CloseOpt(bytes32 indexed sn, bytes32 hashKey);

    event RevokeOpt(bytes32 indexed sn);

    event AddFuture(bytes32 indexed sn, bytes32 shareNumber, uint256 parValue);
    
    event DelFuture(bytes32 indexed sn, bytes32 shareNumber, uint256 parValue);

    // ################
    // ##  Modifier  ##
    // ################

    modifier optionExist(bytes32 sn) {
        require(isOption[sn], "option NOT exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createSN(
        uint8 typeOfOpt, //0-call option; 1-put option
        address obligor,
        uint256 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 price
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.intToSN(0, triggerDate, 4);
        _sn = _sn.intToSN(4, counterOfOptions, 2);
        _sn[6] = bytes1(exerciseDays);
        _sn[7] = bytes1(closingDays);
        _sn[8] = bytes1(typeOfOpt);
        _sn = _sn.addrToSN(9, obligor, 20);
        _sn = _sn.intToSN(29, price, 3);

        sn = _sn.bytesToBytes32();
    }

    function createOption(
        uint8 typeOfOpt,
        address rightholder,
        address obligor,
        uint256 triggerDate,
        uint8 exerciseDays,
        uint8 closingDays,
        uint256 price,
        uint256 parValue
    ) external onlyBookeeper {
        require(typeOfOpt < 2, "typeOfOpt overflow");
        require(triggerDate > now, "triggerDate NOT future");
        require(price > 0, "price is ZERO");
        require(parValue > 0, "ZERO parValue");
        require(exerciseDays > 0, "ZERO exerciseDays");
        require(closingDays > 0, "ZERO closingDays");

        counterOfOpts++;

        bytes32 sn = createSN(
            typeOfOpt,
            obligor,
            triggerDate,
            exerciseDays,
            closingDays,
            price
        );

        Option storage opt = _options[sn];

        opt.rightholder = rightholder;
        opt.parValue = parValue;
        opt.state = 1;

        isOption[sn] = true;
        sn.insertToQue(snList);

        emit CreateOpt(sn, rightholder, parValue);
    }

    function pushToFuture(bytes32 shareNumber, address obligor, uint256 exerciseDate, uint256 closingDate, uint256 price, uint256 parValue) external onlyBookeeper {

        counterOfOpts ++;

        bytes32 sn = createSN(
            1,
            obligor,
            exerciseDate,
            0,
            (closingDate - exerciseDate)/86400,
            price
        );

        Option storage opt = _options[sn];

        opt.rightholder = shareNumber.shareholder();
        opt.parValue = parValue;
        opt.state = 3;

        isOption[sn] = true;
        sn.insertToQue(snList);

        emit CreateOpt(sn, shareNumber.shareholder(), parValue);

        bytes32 ft = _createFuture(shareNumber, parValue);
        futures[sn].push(ft);

        emit AddFuture(sn, shareNumber, parValue);
    }

    function setState(bytes32 sn, uint8 state) external onlyBookeeper {
        _options[sn].state = state;
        emit SetOptState(sn, state);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function getOption(bytes32 sn)
        external
        view
        isOption(sn)
        returns (
            address rightholder,
            uint256 closingDate,
            uint256 parValue,
            bytes32 hashLock,
            uint8 state
        )
    {
        Option memory opt = _options[sn];
        rightholder = opt.rightholder;
        closingDate = opt.closingDate;
        parValue = opt.parValue;
        hashLock = opt.hashLock;
        state = opt.state;
    }

    function parseSN(bytes32 sn)
        public
        pure
        returns (
            uint8 typeOfOpt,
            address obligor,
            uint256 triggerDate,
            uint8 exerciseDays,
            uint8 closingDays,
            uint256 price
        )
    {
        typeOfOpt = uint8(sn[8]);
        obligor = address(bytes20(sn << 72));
        triggerDate = uint256(bytes4(sn));
        exerciseDays = uint8(sn[6]);
        closingDays = uint8(sn[7]);
        price = uint256(bytes3(sn << 232));
    }

    function getSNList() external view returns (bytes32[] list) {
        list = snList;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function execOption(
        bytes32 sn,
        uint256 exerciseDate,
        bytes32 hashLock
    ) external onlyBookeeper optionExist(sn) {
        require(
            exerciseDate >= now - 1 hours && exerciseDate <= now + 1 hours,
            "exerciseDate NOT a current time"
        );

        (
            ,
            ,
            uint256 triggerDate,
            uint8 exerciseDays,
            uint8 closingDays,
            
        ) = parseSN(sn);

        require(exerciseDate >= triggerDate && exerciseDate <= triggerDate + exerciseDays days, "NOT in exercise period");

        Option storage opt = _options[sn];

        opt.closingDate = exerciseDate + closingDays days;
        opt.hashLock = hashLock;
        opt.state = 2;

        emit ExecOpt(sn, exerciseDate, hashLock);
    }

    function _createFuture(bytes32 shareNumber, uint256 parValue) internal pure returns (bytes32 ft) {
        bytes[] _ft = new bytes(32);

        _ft = _ft.bytes32ToSN(0, shareNumber, 1, 6);
        _ft = _ft.intToSN(6, parValue, 26);

        ft = _ft.bytesToBytes32();
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint256 parValue
    ) external onlyBookeeper optionExist(sn) {

        (uint8 typeOfOpt, address obligor, ,,,) = parseSN(sn);

        Option storage opt = _options[sn];

        require(_bos.shareExist(shareNumber), "share NOT exist");

        if (typeOfOpt == 1) require(opt.rightholder == shareNumber.shareholder(), "WRONG shareholder");
        else require(obligor == shareNumber.shareholder(), "WRONG sharehoder");

        require(opt.state == 2, "WRONG state of option");

        (, , uint256 cleanPar,,) = _bos.getShare(shareNumber);
        require(cleanPar >= parValue, "NOT sufficient paidInAmout");

        bytes32 ft = _createFuture(shareNumber, parValue);

        // bytes32[] storage ftList = futures[sn];
        // uint256 len = ftList.length;
        uint256 balance = opt.parValue;

        for (uint256 i=0; i<futures[sn].length; i++) balance -= uint256(futures[sn][i] << 48);

        require(balance >= parValue, "parValue overflow");
        futures[sn].push(ft);

        if (balance == parValue) opt.state = 3;

        emit AddFuture(sn, shareNumber, parValue);
    }

    function removeFuture(bytes32 sn, bytes32 shareNumber, uint256 parValue) external onlyBookeeper optionExist(sn) {
        bytes32 ft = _createFuture(shareNumber, parValue);

        bytes32 storage ftList = futures[sn];

        (bool exist, ) = ftList.firstIndexOf(ft);

        if (exist) {
            ftList.removeByValue(ft);
            _bos.releaseFromFuture(shareNumber, parValue);

            emit DelFuture(sn, shareNumber, parValue);
        }
    };

    function closeOption(bytes32 sn, bytes32 hashKey) external onlyBookeeper optionExist(sn) {
        Option storage opt = _options[sn];

        require(opt.state == 3, "WRONG state");
        require(now <= opt.closingDate + 2 hours && now >= opt.closingDate - 2 hours, "NOT closingDate");
        require(opt.hashLock = keccak256(bytes(hashKey)), "WRONG key");

        opt.state = 4;

        emit CloseOpt(sn, hashKey);

    } 

    function revokeOption(bytes32 sn) external onlyBookeeper optionExist(sn) {
        Option storage opt = _options[sn];

        require (opt.state < 4, "WRONG state");

        if (opt.state == 2 || opt.state == 3) require(now >= opt.closingDate + 2 hours, "NOT expired yet");
        if (opt.state == 1) {
            (,,uint256 triggerDate, uint8 exerciseDays,,) = parseSN(sn);
            require(now >= triggerDate + exerciseDays days + 2 hours, "available to exercise");
        }

        opt.state = 5;

        emit RevokeOpt(sn);
        
    }


    // struct SharesInfo {
    //     uint256 shareNumber;
    //     uint8 class;
    //     uint256 cleanPar;
    // }

    // function _pledgeShares(
    //     uint256 shareNumber,
    //     uint256 pledgedPar,
    //     address shareholder,
    //     address creditor,
    //     uint256 guaranteedAmt
    // ) private {
    //     if (shareNumber > 0) {
    //         _bos.createPledge(shareNumber, pledgedPar, creditor, guaranteedAmt);
    //     } else {
    //         (uint256[] memory sharesList, , ) = _bos.getMember(shareholder);

    //         uint256 i = 0;
    //         uint256[] storage pendingList;

    //         for (; i < sharesList.length; i++) {
    //             // if (amount == 0) break;

    //             (, uint8 class, , , , , , uint8 state) = _bos.getShare(
    //                 sharesList[i]
    //             );

    //             if (paidAmt >= pledgedAmt + amount) {
    //                 _bos.createPledge(
    //                     shareNumber,
    //                     creditor,
    //                     guaranteedAmt,
    //                     pledgedPar
    //                 );
    //                 (sharesList[i], amount);
    //                 amount = 0;
    //             } else {
    //                 _bos.createPledge(
    //                     shareNumber,
    //                     creditor,
    //                     guaranteedAmt,
    //                     pledgedPar
    //                 );
    //                 (sharesList[i], paidAmt - pledgedAmt);
    //                 amount -= (paidAmt - pledgedAmt);
    //             }
    //         }
    //     }
    // }

}
