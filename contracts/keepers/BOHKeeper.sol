/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/IShareholdersAgreement.sol";
import "../books/boh/terms/IGroupsUpdate.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/ruting/IBookSetting.sol";

import "../common/access/IAccessControl.sol";

import "../common/lib/SNParser.sol";
import "../common/lib/EnumsRepo.sol";

import "./IBOHKeeper.sol";

contract BOHKeeper is
    IBOHKeeper,
    BODSetting,
    SHASetting,
    BOMSetting,
    BOOSetting,
    BOSSetting
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
        require(IAccessControl(body).getManager(0) == caller, "not Owner");
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
    ) external onlyManager(1) {
        require(caller == getManager(0), "caller is not Owner");

        termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function createSHA(uint8 docType, address caller) external onlyManager(1) {
        require(_bos.isMember(_rc.userNo(caller)), "not MEMBER");
        address sha = _boh.createDoc(docType, _rc.userNo(caller));

        IAccessControl(sha).init(
            caller,
            this,
            _rc,
            uint8(EnumsRepo.RoleOfUser.ShareholdersAgreement),
            _rc.entityNo(this)
        );

        IShareholdersAgreement(sha).setTermsTemplate(termsTemplate);

        IBookSetting(sha).setBOS(_bos);
        IBookSetting(sha).setBOS(_bosCal);
        IBookSetting(sha).setBOS(_bom);

        copyRoleTo(KEEPERS, sha);

        IAccessControl(sha).setManager(1, _boh);
    }

    function removeSHA(address sha, uint40 caller)
        external
        onlyManager(1)
        onlyOwnerOf(sha, caller)
        notEstablished(sha)
    {
        _boh.removeDoc(sha);
    }

    function circulateSHA(address sha, uint40 caller)
        external
        onlyManager(1)
        onlyOwnerOf(sha, caller)
    {
        require(IAccessControl(sha).finalized(), "let GC finalize SHA first");

        IAccessControl(sha).setManager(0, 0);

        // IAccessControl(sha).abandonOwnership();

        _boh.circulateDoc(sha, bytes32(0), caller);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyPartyOf(sha, caller) {
        require(
            _boh.currentState(sha) == uint8(EnumsRepo.BODStates.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(caller, sigHash);

        if (ISigPage(sha).established()) _boh.pushToNextState(sha, caller);
    }

    function effectiveSHA(address sha, uint40 caller)
        external
        onlyManager(1)
        onlyPartyOf(sha, caller)
    {
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

        _boh.changePointer(sha, caller);

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
