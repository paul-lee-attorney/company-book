/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/interfaces/IShareholdersAgreement.sol";
import "../books/boh/terms/interfaces/IGroupsUpdate.sol";

import "../common/components/EnumsRepo.sol";
import "../common/components/interfaces/ISigPage.sol";

import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/access/interfaces/IAccessControl.sol";
import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/access/interfaces/IRoles.sol";

import "../common/lib/SNParser.sol";

import "../common/utils/Context.sol";

contract BOHKeeper is
    EnumsRepo,
    BOSSetting,
    SHASetting,
    BOMSetting,
    BOOSetting
{
    using SNParser for bytes32;

    address[15] public termsTemplate;

    // ################
    // ##   Events   ##
    // ################

    event AddTemplate(uint8 title, address add);

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier beEstablished(address body) {
        require(ISigPage(body).established(), "Doc NOT Established");
        _;
    }

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint32 caller) {
        require(IAccessControl(body).getOwner() == caller, "not Owner");
        _;
    }

    modifier onlyPartyOf(address body, uint32 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(
        uint8 title,
        address add,
        uint32 caller
    ) external onlyDirectKeeper {
        require(caller == getOwner(), "caller is not Owner");

        termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function createSHA(uint8 docType, uint32 caller) external onlyDirectKeeper {
        require(_bos.isMember(caller), "not MEMBER");
        address body = _boh.createDoc(docType);

        IAccessControl(body).init(
            _rc.userNo(caller),
            _rc.userNo(this),
            address(_rc)
        );

        IShareholdersAgreement(body).setTermsTemplate(termsTemplate);
        IBookSetting(body).setBOM(address(_bom));
        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setBOSCal(address(_bosCal));

        _copyRoleTo(body, KEEPERS);
    }

    function removeSHA(address body, uint32 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(body, caller)
        notEstablished(body)
    {
        _boh.removeDoc(body);
        IShareholdersAgreement(body).kill();
    }

    function submitSHA(
        address body,
        uint32 caller,
        uint32 submitDate,
        bytes32 docHash
    )
        external
        onlyDirectKeeper
        onlyOwnerOf(body, caller)
        beEstablished(body)
        currentDate(submitDate)
    {
        _boh.submitDoc(body, caller, submitDate, docHash);

        IAccessControl(body).abandonOwnership();
    }

    function effectiveSHA(
        address body,
        uint32 caller,
        uint32 sigDate
    ) external onlyDirectKeeper onlyPartyOf(body, caller) {
        require(_boh.isSubmitted(body), "SHA not submitted yet");

        _boh.changePointer(body, caller, sigDate);

        if (IShareholdersAgreement(body).hasTitle(uint8(TermTitle.OPTIONS)))
            _boo.registerOption(
                IShareholdersAgreement(body).getTerm(uint8(TermTitle.OPTIONS))
            );

        if (
            IShareholdersAgreement(body).hasTitle(
                uint8(TermTitle.GROUPS_UPDATE)
            )
        ) {
            bytes32[] memory guo = IGroupsUpdate(
                IShareholdersAgreement(body).getTerm(
                    uint8(TermTitle.GROUPS_UPDATE)
                )
            ).orders();
            uint256 len = guo.length;
            for (uint256 i = 0; i < len; i++) {
                if (guo[i].addMemberOfGUO())
                    _bos.addMemberToGroup(
                        guo[i].memberOfGUO(),
                        guo[i].groupNoOfGUO()
                    );
                else
                    _bos.removeMemberFromGroup(
                        guo[i].memberOfGUO(),
                        guo[i].groupNoOfGUO()
                    );
            }
        }
    }
}
