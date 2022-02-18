/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../interfaces/IBookOfDocuments.sol";
import "../interfaces/IBookOfShares.sol";
import "../interfaces/IBookOfMotions.sol";
import "../interfaces/IShareholdersAgreement.sol";

interface IBooks {
    function setBOS(address bos) external;

    function setBOM(address bos) external;

    function setBOA(address bos) external;

    function setBOH(address bos) external;

    function getBOS() external view returns (IBookOfShares);

    function getBOM() external view returns (IBookOfMotions);

    function getBOH() external view returns (IBookOfDocuments);

    function getSHA() external view returns (IShareholdersAgreement);

    function getBOA() external view returns (IBookOfDocuments);
}
