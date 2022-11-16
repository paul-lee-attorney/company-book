// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boa/IInvestmentAgreement.sol";
import "../books/boh/ShareholdersAgreement.sol";
import "../books/boo/BookOfOptions.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/ruting/ROMSetting.sol";

import "../common/lib/SNFactory.sol";
import "../common/lib/SNParser.sol";

import "../common/components/ISigPage.sol";

import "../common/lib/MotionsRepo.sol";

import "./IBOMKeeper.sol";

contract BOMKeeper is
    IBOMKeeper,
    BOASetting,
    BODSetting,
    BOMSetting,
    SHASetting,
    BOOSetting,
    BOSSetting,
    ROMSetting
{
    using SNFactory for bytes;
    using SNParser for bytes32;

    // ################
    // ##   Motion   ##
    // ################

    function entrustDelegate(
        uint40 caller,
        uint40 delegate,
        uint256 actionId
    ) external onlyManager(1) memberExist(caller) memberExist(delegate) {
        _bom.entrustDelegate(caller, delegate, actionId);
    }

    // ==== propose ====

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyManager(1)
        memberExist(nominator)
    {
        _bom.nominateDirector(candidate, nominator);
    }

    function proposeIA(address ia, uint40 caller)
        external
        onlyManager(1)
        memberExist(caller)
    {
        require(
            ISigPage(ia).isParty(caller),
            "BOMKeeper.proposeIA: NOT Party of Doc"
        );

        require(
            _boa.currentState(ia) == uint8(DocumentsRepo.BODStates.Established),
            "InvestmentAgreement not on Established"
        );

        if (_subjectToReview(ia))
            require(
                _boa.reviewDeadlineBNOf(ia) < block.number,
                "BOMKeeper.proposeMotion: IA not passed review procesedure"
            );

        require(
            _boa.votingDeadlineBNOf(ia) >= block.number,
            "missed votingDeadlineBN"
        );

        bytes32 vr = _getSHA().votingRules(_boa.typeOfIA(ia));

        if (vr.ratioHeadOfVR() > 0 || vr.ratioAmountOfVR() > 0)
            _bom.proposeIA(ia, caller);

        _boa.pushToNextState(ia);

        _bom.proposeIA(ia, caller);
    }

    function _subjectToReview(address ia) private view returns (bool) {
        bytes32[] memory dealsList = IInvestmentAgreement(ia).dealsList();
        uint256 len = dealsList.length;

        while (len > 0) {
            bytes32 sn = dealsList[len - 1];
            len--;

            if (
                _getSHA().hasTitle(
                    uint8(ShareholdersAgreement.TermTitle.FIRST_REFUSAL)
                ) &&
                _getSHA().termIsTriggered(
                    uint8(ShareholdersAgreement.TermTitle.FIRST_REFUSAL),
                    ia,
                    sn
                )
            ) return true;

            if (
                _getSHA().hasTitle(
                    uint8(ShareholdersAgreement.TermTitle.TAG_ALONG)
                ) &&
                _getSHA().termIsTriggered(
                    uint8(ShareholdersAgreement.TermTitle.TAG_ALONG),
                    ia,
                    sn
                )
            ) return true;

            if (
                _getSHA().hasTitle(
                    uint8(ShareholdersAgreement.TermTitle.DRAG_ALONG)
                ) &&
                _getSHA().termIsTriggered(
                    uint8(ShareholdersAgreement.TermTitle.DRAG_ALONG),
                    ia,
                    sn
                )
            ) return true;
        }

        return false;
    }

    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter
    ) external onlyManager(1) memberExist(submitter) {
        _bom.proposeAction(
            actionType,
            targets,
            values,
            params,
            desHash,
            submitter
        );
    }

    // ==== vote ====

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) memberExist(caller) {
        if (_isIA(motionId))
            require(
                !ISigPage(address(uint160(motionId))).isParty(caller),
                "BOMKeeper.castVote: Party has no voting right"
            );

        _bom.castVote(motionId, attitude, caller, sigHash);
    }

    function _isIA(uint256 motionId) private pure returns (bool) {
        return motionId > 0 && ((motionId >> 160) == 0);
    }

    function voteCounting(uint256 motionId, uint40 caller)
        external
        onlyManager(1)
        memberExist(caller)
    {
        _bom.voteCounting(motionId);

        if (_isIA(motionId))
            _boa.pushToNextState(address(uint160(motionId)));
    }

    // ==== execute ====

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 caller
    ) external returns (uint256) {
        require(_bod.isDirector(caller), "caller is not a Director");
        require(!_rc.isContract(caller), "caller is not an EOA");
        return _bom.execAction(actionType, targets, values, params, desHash);
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint40 againstVoter,
        uint40 caller
    ) external onlyManager(1) {
        require(
            _bom.state(uint256(uint160(ia))) ==
                uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "agianst NO need to buy"
        );

        bytes32 shareNumber = IInvestmentAgreement(ia).shareNumberOfDeal(
            sn.sequence()
        );

        require(caller == shareNumber.shareholder(), "NOT Seller of the Deal");

        uint32 unitPrice = IInvestmentAgreement(ia).unitPriceOfDeal(
            sn.sequence()
        );
        uint32 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            sn.sequence()
        );

        (uint64 paid, uint64 par) = _bom.requestToBuy(ia, sn);

        uint8 closingDays = uint8(
            (closingDate - uint32(block.number) + 12 * _rc.blocksPerHour()) /
                (24 * _rc.blocksPerHour())
        );

        bytes32 snOfOpt = _createOptSN(
            uint8(BookOfOptions.TypeOfOption.Put_Price),
            uint32(block.number),
            1,
            closingDays,
            shareNumber.class(),
            unitPrice
        );

        uint40[] memory obligors = new uint40[](1);
        obligors[0] = againstVoter;

        snOfOpt = _boo.createOption(snOfOpt, caller, obligors, paid, par);

        _boo.execOption(snOfOpt);
        _boo.addFuture(snOfOpt, shareNumber, paid, par);
    }

    function _createOptSN(
        uint8 typeOfOpt,
        uint32 triggerBN,
        uint8 execDays,
        uint8 closingDays,
        uint16 classOfOpt,
        uint32 rateOfOpt
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.dateToSN(5, triggerBN);
        _sn[9] = bytes1(execDays);
        _sn[10] = bytes1(closingDays);
        _sn = _sn.sequenceToSN(11, classOfOpt);
        _sn = _sn.dateToSN(13, rateOfOpt);

        sn = _sn.bytesToBytes32();
    }
}
