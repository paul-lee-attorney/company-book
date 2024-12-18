/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh//IShareholdersAgreement.sol";
import "../books/boh/terms//IGroupsUpdate.sol";
import "../books/boh/ShareholdersAgreement.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/access/IAccessControl.sol";
import "../common/ruting/IBookSetting.sol";
import "../common/access/IRoles.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";

import "./IBOHKeeper.sol";

// import "../common/utils/Context.sol";

contract BOHKeeper is
    IBOHKeeper,
    BOSSetting,
    SHASetting,
    BOMSetting,
    BOOSetting,
    BODSetting
{
    using SNParser for bytes32;

    address[15] public termsTemplate;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(IAccessControl(body).getOwner() == caller, "not Owner");
        _;
    }

    modifier onlyPartyOf(address body, uint40 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(
        uint8 title,
        address add,
        uint40 caller
    ) external onlyDirectKeeper {
        require(caller == getOwner(), "caller is not Owner");

        termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function createSHA(uint8 docType, uint40 caller) external onlyDirectKeeper {
        require(_bos.isMember(caller), "not MEMBER");
        address sha = _boh.createDoc(docType, caller);

        IAccessControl(sha).init(caller, _rc.userNo(this), address(_rc));

        IShareholdersAgreement(sha).setTermsTemplate(termsTemplate);
        IBookSetting(sha).setBOM(address(_bom));
        IBookSetting(sha).setBOS(address(_bos));
        IBookSetting(sha).setBOSCal(address(_bosCal));

        _copyRoleTo(sha, KEEPERS);
    }

    function removeSHA(address sha, uint40 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(sha, caller)
        notEstablished(sha)
    {
        _boh.removeDoc(sha, caller);
    }

    function circulateSHA(address sha, uint40 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(sha, caller)
    {
        require(IDraftControl(sha).finalized(), "let GC finalize SHA first");

        IAccessControl(sha).abandonOwnership();

        _boh.circulateDoc(sha, bytes32(0), caller);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        require(
            _boh.currentState(sha) == uint8(EnumsRepo.BODStates.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(caller, sigHash);

        if (ISigPage(sha).established()) _boh.pushToNextState(sha, caller);
    }

    function effectiveSHA(
        address sha,
        uint40 caller,
        uint32 sigDate
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) currentDate(sigDate) {
        require(
            _boh.currentState(sha) == uint8(EnumsRepo.BODStates.Established),
            "SHA not executed yet"
        );

        uint40[] memory members = _bos.members();
        uint256 len = members.length;
        while (len > 0) {
            require(
                ISigPage(sha).isParty(members[len - 1]),
                "left member for SHA"
            );
            len--;
        }

        _boh.changePointer(sha, caller, sigDate);

        _bod.setMaxNumOfDirectors(
            IShareholdersAgreement(sha).maxNumOfDirectors()
        );

        if (
            IShareholdersAgreement(sha).hasTitle(
                uint8(EnumsRepo.TermTitle.OPTIONS)
            )
        )
            _boo.registerOption(
                IShareholdersAgreement(sha).getTerm(
                    uint8(EnumsRepo.TermTitle.OPTIONS)
                )
            );

        if (
            IShareholdersAgreement(sha).hasTitle(
                uint8(EnumsRepo.TermTitle.GROUPS_UPDATE)
            )
        ) {
            bytes32[] memory guo = IGroupsUpdate(
                IShareholdersAgreement(sha).getTerm(
                    uint8(EnumsRepo.TermTitle.GROUPS_UPDATE)
                )
            ).orders();
            len = guo.length;
            while (len > 0) {
                if (guo[len - 1].addMemberOfGUO())
                    _bos.addMemberToGroup(
                        guo[len - 1].memberOfGUO(),
                        guo[len - 1].groupNoOfGUO()
                    );
                else
                    _bos.removeMemberFromGroup(
                        guo[len - 1].memberOfGUO(),
                        guo[len - 1].groupNoOfGUO()
                    );
                len--;
            }
        }
    }
}
