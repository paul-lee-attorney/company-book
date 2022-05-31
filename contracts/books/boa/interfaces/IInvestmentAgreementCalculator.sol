/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

contract IInvestmentAgreementCalculator {
    function parToSell(address ia, uint32 acct)
        external
        view
        returns (uint256 output);

    function paidToSell(address ia, uint32 acct)
        external
        view
        returns (uint256 output);

    function parToSellOfGroup(address ia, uint16 group)
        external
        view
        returns (uint256 output);

    function paidToSellOfGroup(address ia, uint16 group)
        external
        view
        returns (uint256 output);

    function parToBuy(address ia, uint32 acct)
        internal
        view
        returns (uint256 output);

    function paidToBuy(address ia, uint32 acct)
        internal
        view
        returns (uint256 output);

    function parToBuyOfGroup(address ia, uint16 group)
        external
        view
        returns (uint256 output);

    function paidToBuyOfGroup(address ia, uint16 group)
        external
        view
        returns (uint256 output);

    function groupsInvolved(address ia) public view returns (uint16[]);

    function controllerToBeChanged(address ia, bool basedOnPar)
        public
        view
        returns (bool flag, uint256 ratio);

    function typeOfIA(address ia) external view returns (uint8 output);

    function otherMembers(address ia) external view returns (uint32[]);
}
